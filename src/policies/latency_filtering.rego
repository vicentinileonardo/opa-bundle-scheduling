package system

import rego.v1

provider := data.userSettings.cloudProvider

# Function to determine eligible regions based on latency
# In theory at least 1 region should be eligible: the origin region itself
eligible_regions_by_latency(origin_region, max_latency) = eligible if {
    latency_matrix := data[provider].latency_matrix
    eligible := {target_region |
        some target_region
        latency := latency_matrix[origin_region][target_region]
        latency != "N/A";
        to_number(latency) <= max_latency
    }
}
