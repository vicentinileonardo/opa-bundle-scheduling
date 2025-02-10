package system

import rego.v1

provider := data.userSettings.cloudProvider

# Utility functions to map between cloud provider regions and ElectricityMaps regions

map_to_electricitymaps(eligible_regions, provider) = em_regions if {
    em_regions := {
        region.ElectricityMapsName |                # Pipe is a set comprehension, everything after the pipe defines the conditions and variables used to generate the set               
        some eligible_region;                       # Bind an eligible_region from the input
        some region;                                # Bind a region from the provider's cloud regions
        eligible_region = eligible_regions[_];      # Iterate over eligible regions
        region = data[provider].cloud_regions[_];   # Iterate over provider regions
        region.Name == eligible_region              # Match cloud region name
        region.ElectricityMapsName != ""            # ElectricityMaps region is not empty
        region.ElectricityMapsName != "Unknown"     # ElectricityMaps region is not "Unknown"  
    }
}

# It could be that multiple cloud regions map to the same ElectricityMaps region
# In that case, we simply return the first cloud region that matches the ElectricityMaps region (arbitrary choice)
map_from_electricitymaps(em_region, provider) = cloud_region if {
    some region;                                # Bind a region from the provider's cloud regions
    region = data[provider].cloud_regions[_];   # Iterate over provider regions
    region.ElectricityMapsName == em_region;    # Match ElectricityMaps name
    cloud_region := region.Name                 # Return the cloud provider region name
}
