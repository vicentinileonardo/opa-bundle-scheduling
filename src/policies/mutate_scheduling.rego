package system

# Reference: https://github.com/open-policy-agent/library/blob/master/kubernetes/mutating-admission/example_mutation.rego

############################################################
# PATCH rules for VmTemplate scheduling time and location
#
# Adds or replaces schedulingTime and schedulingLocation in VmTemplate spec
############################################################

const_scheduling_time := data.userSettings.defaultSchedulingTime		 # Hardcoded ISO 8601 timestamp (for fallback)
const_scheduling_location := data.userSettings.defaultSchedulingLocation # Hardcoded 'italynorth' (azure) (for fallback)

# Retrieve URL from environment variable (OPA configuration)
scheduler_url := opa.runtime().env.SCHEDULER_URL

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
		"number_of_jobs": 1, # currently only one job (workload (VM)) can be scheduled at a time
		"eligible_regions": eligible_electricity_maps_regions,
		"deadline": deadline,
		"duration": duration, 
		"cpu": cpu,
		"memory": memory,
		"req_timeout": "10s" # scheduler wants to know the timeout to tune the execution time of the optimization
	},
	"timeout": "10s",
})

# NOTE: If there is an UPDATE operation and the external request to the scheduler fails, 
# the existing schedulingTime and schedulingLocation will be retained. That's why there 
# is no fallback rule for UPDATE.

##### TIME #####

# CREATE, EXTERNAL REQUEST OK
patch[patchCode] {
	isValidRequest
	isCreate
	input.request.kind.kind == "VmTemplate"

	# Log the HTTP request details
	print(sprintf("HTTP Response Body: %s", [scheduling_details.body]))
	print(sprintf("HTTP Response Status Code: %d", [scheduling_details.status_code]))

	# Ensure HTTP call was successful
	scheduling_details.status_code == 200
	schedulingTime := scheduling_details.body.schedulingTime
	print(sprintf("schedulingTime: %s", [schedulingTime]))

	# Patch to add schedulingTime if not present (i.e. create)
	not input.request.object.spec.schedulingTime
	patchCode = {
		"op": "add",
		"path": "/spec/schedulingTime",
		"value": schedulingTime,
	}
}

# CREATE, Fallback rule in case HTTP call fails with status code != 200
patch[patchCode] {
    isValidRequest
    isCreate
    input.request.kind.kind == "VmTemplate"

    # Check for failed HTTP call
    scheduling_details.status_code != 200

    print(sprintf("Falling back to default scheduling time. Status code: %v", [scheduling_details.status_code]))

	# Patch to add schedulingTime if not present (i.e. create)
	not input.request.object.spec.schedulingTime
    patchCode := {
        "op": "add",
        "path": "/spec/schedulingTime",
        "value": const_scheduling_time
    }
}

# CREATE, Fallback rule in case of missing scheduling details
patch[patchCode] {
    isValidRequest
    isCreate
    input.request.kind.kind == "VmTemplate"
    not scheduling_details

    print("Falling back to default scheduling time. No details available.")

	# Patch to add schedulingTime if not present (i.e. create)
	not input.request.object.spec.schedulingTime
    patchCode := {
        "op": "add",
        "path": "/spec/schedulingTime",
        "value": const_scheduling_time
    }
}

# UPDATE, EXTERNAL REQUEST OK
patch[patchCode] {
	isValidRequest
	isUpdate
	input.request.kind.kind == "VmTemplate"

	# check if label is present
	input.request.object.metadata.labels["greenops-optimization"]

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
}

##### LOCATION #####

# CREATE, EXTERNAL REQUEST OK
patch[patchCode] {
	isValidRequest
	isCreate
	input.request.kind.kind == "VmTemplate"

	# Log the HTTP request details
	print(sprintf("HTTP Response Body: %s", [scheduling_details.body]))
	print(sprintf("HTTP Response Status Code: %d", [scheduling_details.status_code]))

	# Ensure HTTP call was successful
	scheduling_details.status_code == 200
	schedulingLocation := scheduling_details.body.schedulingLocation
	print(sprintf("schedulingLocation: %s", [schedulingLocation]))

	# Patch to add schedulingLocation if not present (i.e. create)
	not input.request.object.spec.schedulingLocation
	patchCode = {
		"op": "add",
		"path": "/spec/schedulingLocation",
		"value": schedulingLocation,
	}
}

# CREATE, Fallback rule in case HTTP call fails with status code != 200
patch[patchCode] {
    isValidRequest
    isCreate
    input.request.kind.kind == "VmTemplate"

    # Check for failed HTTP call
    scheduling_details.status_code != 200

    print(sprintf("Falling back to default scheduling location. Status code: %v", [scheduling_details.status_code]))

	# Patch to add schedulingTime if not present (i.e. create)
	not input.request.object.spec.schedulingLocation
    patchCode := {
        "op": "add",
        "path": "/spec/schedulingLocation",
        "value": const_scheduling_location
    }
}

# CREATE, Fallback rule in case of missing scheduling details
patch[patchCode] {
    isValidRequest
    isCreate
    input.request.kind.kind == "VmTemplate"
    not scheduling_details

    print("Falling back to default scheduling location. No details available.")

	# Patch to add schedulingTime if not present (i.e. create)
	not input.request.object.spec.schedulingLocation
    patchCode := {
        "op": "add",
        "path": "/spec/schedulingLocation",
        "value": const_scheduling_location
    }
}

# UPDATE, EXTERNAL REQUEST OK
patch[patchCode] {
	isValidRequest
	isUpdate
	input.request.kind.kind == "VmTemplate"

	# check if label is present
	input.request.object.metadata.labels["greenops-optimization"]

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
}
