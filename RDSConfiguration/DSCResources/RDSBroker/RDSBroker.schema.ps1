Configuration RDSBroker {
    WindowsFeature 'Remote-Desktop-Services' {
        Name = 'Remote-Desktop-Services'
        Ensure = 'Present'
        IncludeAllSubFeature = $true
    }
    WindowsFeature 'RDS-Connection-Broker' {
        Name = 'RDS-Connection-Broker'
        Ensure = 'Present'
        IncludeAllSubFeature = $true
        DependsOn = '[WindowsFeature]Remote-Desktop-Services'
    }

    WindowsFeature 'RDS-Licensing' {
        Name = 'RDS-Licensing'
        Ensure = 'Present'
        IncludeAllSubFeature = $true
        DependsOn = '[WindowsFeature]Remote-Desktop-Services'
    }

    WindowsFeature 'RDS-Web-Access' {
        Name = 'RDS-Web-Access'
        Ensure = 'Present'
        IncludeAllSubFeature = $true
        DependsOn = '[WindowsFeature]Remote-Desktop-Services'
    }
}
