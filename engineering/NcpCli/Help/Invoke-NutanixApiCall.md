---
external help file: Nutanix.NcpCli.Core.psm1-help.xml
Module Name: Nutanix.NcpCli
online version: https://github.com/nutanix-enterprise/solutions-euc/blob/main/engineering/NcpCli/Help/Nutanix/Invoke-NutanixApiCall.md
schema: 2.0.0
---

# Invoke-NutanixApiCall

## SYNOPSIS
Executes an API call against a Nutanix Prism Central instance.

## SYNTAX

```
Invoke-NutanixApiCall [-PrismIP] <String> [-PrismUserName] <String> [-PrismPassword] <String>
 [-ApiPath] <String> [[-Body] <String>] [[-ContentType] <String>] [[-Method] <Object>] [<CommonParameters>]
```

## DESCRIPTION
This function will run an Api call against Prism Central and will either return the result data for the call or the error message as to why the call failed.

## EXAMPLES

### EXAMPLE 1
```
$Alerts = Invoke-NutanixApiCall -PrismIP "10.10.10.10" -PrismUserName "admin" -PrismPassword "password" -ApiPath "prism/v4.0.a1/alerts"
Gets the current alerts from the Prism Central Appliance.
```

### EXAMPLE 2
```
Invoke-NutanixApiCall -PrismIP "10.10.10.10" -PrismUserName "admin" -PrismPassword "password" -ApiPath "prism/v4.0.a2/config/categories"
Gets the categories from the Prism Central Appliance.
```

## PARAMETERS

### -PrismIP
Specifies the Prism Central IP

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: True
Position: 1
Default value: None
Accept pipeline input: True (ByPropertyName)
Accept wildcard characters: False
```

### -PrismUserName
Specifies the Prism Central User Name

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: True
Position: 2
Default value: None
Accept pipeline input: True (ByPropertyName)
Accept wildcard characters: False
```

### -PrismPassword
Specifies the Prism Central Password

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: True
Position: 3
Default value: None
Accept pipeline input: True (ByPropertyName)
Accept wildcard characters: False
```

### -ApiPath
Specifies the Prism Central Api Path to query

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: True
Position: 4
Default value: None
Accept pipeline input: True (ByPropertyName)
Accept wildcard characters: False
```

### -Body
(Optional) Specifies the Body to send to the Api Query

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: False
Position: 5
Default value: None
Accept pipeline input: True (ByPropertyName)
Accept wildcard characters: False
```

### -ContentType
Specifies the Content Type for the Api Call

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: False
Position: 6
Default value: Application/json
Accept pipeline input: False
Accept wildcard characters: False
```

### -Method
Specifies the Method you with to use for the query (POST, GET, PUT, DELETE)

```yaml
Type: Object
Parameter Sets: (All)
Aliases:

Required: False
Position: 7
Default value: GET
Accept pipeline input: False
Accept wildcard characters: False
```

### CommonParameters
This cmdlet supports the common parameters: -Debug, -ErrorAction, -ErrorVariable, -InformationAction, -InformationVariable, -OutVariable, -OutBuffer, -PipelineVariable, -Verbose, -WarningAction, and -WarningVariable. For more information, see [about_CommonParameters](http://go.microsoft.com/fwlink/?LinkID=113216).

## INPUTS

### This function will take inputs via pipeline as string
## OUTPUTS

### Returns an object with the query result and either the data from the query or the error message
## NOTES

## RELATED LINKS

[https://github.com/nutanix-enterprise/solutions-euc/blob/main/engineering/NcpCli/Help/Nutanix/Invoke-NutanixApiCall.md](https://github.com/nutanix-enterprise/solutions-euc/blob/main/engineering/NcpCli/Help/Nutanix/Invoke-NutanixApiCall.md)

[Project Site: https://github.com/nutanix-enterprise/solutions-euc/blob/main/engineering/NcpCli]()

