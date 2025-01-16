package system

# Reference: https://github.com/open-policy-agent/library/blob/master/kubernetes/mutating-admission/example_mutation.rego

############################################################
# PATCH rules for VmTemplate scheduling time and location
#
# Adds or replaces schedulingTime and schedulingLocation in VmTemplate spec
############################################################

const_scheduling_time := data.userSettings.defaultSchedulingTime			# Hardcoded ISO 8601 timestamp (for fallback)
const_scheduling_location := data.userSettings.defaultSchedulingLocation

#scheduler_url := "http://ai-inference-server-mock.ai-inference-server-mock.svc.cluster.local:8080/scheduling"

# Retrieve URL from environment variable (OPA configuration)
scheduler_url := opa.runtime().env.AI_INFERENCE_SERVER_MOCK_URL

origin_region := data.userSettings.originRegion
max_latency := input.request.object.spec.maxLatency
deadline := input.request.object.spec.deadline
duration := input.request.object.spec.duration
cpu := input.request.object.spec.cpu
memory := input.request.object.spec.memory

eligible_regions = latency_eligible_regions {
	data.userSettings.gdprCompliance.enabled == false
    
    # Get regions eligible by latency
    latency_eligible_regions := eligible_regions_by_latency(origin_region, max_latency)
}

eligible_regions = latency_and_gdpr_eligible_regions {
	data.userSettings.gdprCompliance.enabled == true

    # Get regions eligible by latency
    latency_eligible_regions := eligible_regions_by_latency(origin_region, max_latency)

    # Filter latency-eligible regions by GDPR compliance
    latency_and_gdpr_eligible_regions = eligible_regions_by_gdpr(latency_eligible_regions)
}

eligible_electricity_maps_regions = result {
    result := map_to_electricitymaps(eligible_regions, provider)
}

# HTTP call to get scheduling details
scheduling_details := http.send({
	"method": "POST",
	"url": scheduler_url,
	"body": {
		"eligible_regions": eligible_electricity_maps_regions,
		"deadline": deadline,
		"duration": duration, 
		"cpu": cpu,
		"memory": memory,
		"req_timeout": "10s" # scheduler wants to know the timeout
	},
	"timeout": "10s",
})

##### TIME #####

# Patch to add or replace schedulingTime in VmTemplate spec
patch[patchCode] {
	isValidRequest
	isCreateOrUpdate
	input.request.kind.kind == "VmTemplate"

	# Log the HTTP request details
	print(sprintf("HTTP Response Body: %s", [scheduling_details.body]))
	print(sprintf("HTTP Response Status Code: %d", [scheduling_details.status_code]))

	# Ensure HTTP call was successful
	scheduling_details.status_code == 200
	schedulingTime := scheduling_details.body.schedulingTime
	print(sprintf("schedulingTime: %s", [schedulingTime]))

	# Patch to add schedulingTime if not present
	not input.request.object.spec.schedulingTime
	patchCode = {
		"op": "add",
		"path": "/spec/schedulingTime",
		"value": schedulingTime,
	}

	print("with ENV_VARIABLE (1)")
	print("After TIME add patch (1)")
}

patch[patchCode] {
	isValidRequest
	isCreateOrUpdate
	input.request.kind.kind == "VmTemplate"

	# Log the HTTP request details
	print(sprintf("HTTP Response Body: %s", [scheduling_details.body]))
	print(sprintf("HTTP Response Status Code: %d", [scheduling_details.status_code]))

	# Ensure HTTP call was successful
	scheduling_details.status_code == 200
	schedulingTime := scheduling_details.body.schedulingTime
	print(sprintf("schedulingTime: %s", [schedulingTime]))

	# Patch to replace existing schedulingTime
	input.request.object.spec.schedulingTime
	patchCode = {
		"op": "replace",
		"path": "/spec/schedulingTime",
		"value": schedulingTime,
	}
	
	print("with ENV_VARIABLE (2)")
	print("After TIME replace patch (2)")
}

# Fallback rules in case HTTP call fails
patch[patchCode] {
	isValidRequest
	isCreateOrUpdate
	input.request.kind.kind == "VmTemplate"

	# Fallback to default if HTTP call fails
	scheduling_details.status_code != 200
	print(sprintf("pFallback, status code: %d", [scheduling_details.status_code]))

	patchCode = {
		"op": "add",
		"path": "/spec/schedulingTime",
		"value": const_scheduling_time,
	}

	print("After TIME fallback patch (3)")
}


##### LOCATION #####

# Patch to add or replace schedulingLocation in VmTemplate spec
patch[patchCode] {
	isValidRequest
	isCreateOrUpdate
	input.request.kind.kind == "VmTemplate"

	# Log the HTTP request details
	print(sprintf("HTTP Response Body: %s", [scheduling_details.body]))
	print(sprintf("HTTP Response Status Code: %d", [scheduling_details.status_code]))

	# Ensure HTTP call was successful
	scheduling_details.status_code == 200
	schedulingLocation := scheduling_details.body.schedulingLocation
	print(sprintf("schedulingLocation: %s", [schedulingLocation]))

	# Patch to add schedulingLocation if not present
	not input.request.object.spec.schedulingLocation
	patchCode = {
		"op": "add",
		"path": "/spec/schedulingLocation",
		"value": schedulingLocation,
	}

	print("After LOCATION add patch (1)")
}

patch[patchCode] {
	isValidRequest
	isCreateOrUpdate
	input.request.kind.kind == "VmTemplate"

	# Log the HTTP request details
	print(sprintf("HTTP Response Body: %s", [scheduling_details.body]))
	print(sprintf("HTTP Response Status Code: %d", [scheduling_details.status_code]))

	# Ensure HTTP call was successful
	scheduling_details.status_code == 200
	schedulingLocation := scheduling_details.body.schedulingLocation
	print(sprintf("schedulingLocation: %s", [schedulingLocation]))

	# Patch to replace existing schedulingTime
	input.request.object.spec.schedulingLocation
	patchCode = {
		"op": "replace",
		"path": "/spec/schedulingLocation",
		"value": schedulingLocation,
	}

	print("After LOCATION replace patch (2)")
}

# Fallback rules in case HTTP call fails
patch[patchCode] {
	isValidRequest
	isCreateOrUpdate
	input.request.kind.kind == "VmTemplate"

	# Fallback to default if HTTP call fails
	scheduling_details.status_code != 200
	print(sprintf("pFallback, status code: %d", [scheduling_details.status_code]))

	patchCode = {
		"op": "add",
		"path": "/spec/schedulingLocation",
		"value": const_scheduling_location
	}

	print("After LOCATION fallback patch (3)")
}
