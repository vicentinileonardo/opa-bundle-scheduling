package system

# https://github.com/open-policy-agent/library/blob/master/kubernetes/mutating-admission/example_mutation.rego
############################################################
# PATCH rules for VmTemplate scheduling time
#
# Adds or replaces schedulingTime in VmTemplate spec with a hardcoded ISO 8601 timestamp
############################################################

# Hardcoded ISO 8601 timestamp
const_scheduling_time := "2049-03-15T11:34:45Z"

# HTTP call to get scheduling details
scheduling_details := http.send({
	"method": "GET",
	"url": "http://ai-inference-server-mock.ai-inference-server-mock.svc.cluster.local:8080/scheduling",
	"timeout": "10s",
})

# Patch to add or replace schedulingTime in VmTemplate spec
patch[patchCode] {
	isValidRequest
	isCreateOrUpdate
	input.request.kind.kind == "VmTemplate"

	# Log the HTTP request details
	print(sprintf("[UPDATED] HTTP Response Body: %s", [scheduling_details.body]))
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

	print("After add patch (1)")
}

patch[patchCode] {
	isValidRequest
	isCreateOrUpdate
	input.request.kind.kind == "VmTemplate"

	# Log the HTTP request details
	print(sprintf("[UPDATED] HTTP Response Body: %s", [scheduling_details.body]))
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

	print("After replace patch (2)")
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

	print("After fallback patch (3)")
}
