function New-TestId {

    $GUID = (New-Guid).Guid.SubString(1,6)
    Return $GUID

}