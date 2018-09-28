function Get-GSCourse {
    <#
    .SYNOPSIS
    Gets a classroom course or list of courses

    .DESCRIPTION
    Gets a classroom course or list of courses

    .PARAMETER Id
    Identifier of the course to return. This identifier can be either the Classroom-assigned identifier or an alias.

    If excluded, returns the list of courses.

    .PARAMETER User
    The user to request course information as

    .PARAMETER Teacher
    Restricts returned courses to those having a teacher with the specified identifier. The identifier can be one of the following:

    * the numeric identifier for the user
    * the email address of the user
    * the string literal "me", indicating the requesting user

    .PARAMETER Student
    Restricts returned courses to those having a student with the specified identifier. The identifier can be one of the following:

    * the numeric identifier for the user
    * the email address of the user
    * the string literal "me", indicating the requesting user

    .PARAMETER CourseStates
    Restricts returned courses to those in one of the specified states The default value is ACTIVE, ARCHIVED, PROVISIONED, DECLINED, SUSPENDED.

    .EXAMPLE
    Get-GSCourse -Teacher aristotle@athens.edu
    #>
    [cmdletbinding(DefaultParameterSetName = "List")]
    Param
    (
        [parameter(Mandatory = $false,Position = 0,ParameterSetName = "Get")]
        [ValidateNotNullOrEmpty()]
        [String[]]
        $Id,
        [parameter(Mandatory = $false)]
        [String]
        $User = $Script:PSGSuite.AdminEmail,
        [parameter(Mandatory = $false,ParameterSetName = "List")]
        [String]
        $Teacher,
        [parameter(Mandatory = $false,ParameterSetName = "List")]
        [String]
        $Student,
        [parameter(Mandatory = $false,ParameterSetName = "List")]
        [ValidateSet('ACTIVE','ARCHIVED','PROVISIONED','DECLINED','SUSPENDED')]
        [String[]]
        $CourseStates = @('ACTIVE','ARCHIVED','PROVISIONED','DECLINED','SUSPENDED')
    )
    Begin {
        $serviceParams = @{
            Scope       = 'https://www.googleapis.com/auth/classroom.courses'
            ServiceType = 'Google.Apis.Classroom.v1.ClassroomService'
            User        = $User
        }
        $service = New-GoogleService @serviceParams
    }
    Process {
        if ($PSBoundParameters.Keys -contains 'Id') {
            foreach ($I in $Id) {
                try {
                    Write-Verbose "Getting Course '$Id'"
                    $request = $service.Courses.Get($Id)
                    $request.Execute()
                }
                catch {
                    if ($ErrorActionPreference -eq 'Stop') {
                        $PSCmdlet.ThrowTerminatingError($_)
                    }
                    else {
                        Write-Error $_
                    }
                }
            }
        }
        else {
            try {
                Write-Verbose "Getting Course List"
                $request = $service.Courses.List()
                foreach ($s in $CourseStates) {
                    $request.CourseStates += [Google.Apis.Classroom.v1.CoursesResource+ListRequest+CourseStatesEnum]::$s
                }
                if ($PSBoundParameters.Keys -contains 'Student') {
                    $request.StudentId = $PSBoundParameters['Student']
                }
                if ($PSBoundParameters.Keys -contains 'Teacher') {
                    $request.TeacherId = $PSBoundParameters['Teacher']
                }
                [int]$i = 1
                do {
                    $result = $request.Execute()
                    if ($null -ne $result.Courses) {
                        $result.Courses
                    }
                    $request.PageToken = $result.NextPageToken
                    [int]$retrieved = ($i + $result.Courses.Count) - 1
                    Write-Verbose "Retrieved $retrieved Courses..."
                    [int]$i = $i + $result.Courses.Count
                }
                until (!$result.NextPageToken)
            }
            catch {
                if ($ErrorActionPreference -eq 'Stop') {
                    $PSCmdlet.ThrowTerminatingError($_)
                }
                else {
                    Write-Error $_
                }
            }
        }
    }
}
