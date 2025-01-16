package system

import rego.v1

provider := data.userSettings.cloudProvider

eligible_regions_by_gdpr(regions) = eligible if {
    gdpr_compliant_regions := data[provider].gdpr_compliant_regions
    eligible := {r | 
        some r in regions
        r in gdpr_compliant_regions
    }
}
