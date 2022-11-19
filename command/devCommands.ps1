### MAVEN

function minst() {
    mvn install	
}

### JAVA

function jrun() { #? java compile hello.java && java hello
    param(
        [Parameter(Mandatory)]$file
    )

    $filenameParts = $file.split(".")
    If ($filenameParts.Length -Eq 2 -AND $filenameParts[1].Equals("java")) {
    } Elseif ($filenameParts.Length -Eq 1) {
        $file = $file + ".java"
    }

    If (-Not(Test-Path $file)) {
        Write-Error "File doesn't exist !"
        Return
    }

    javac $file

    # return if javac failed
    If (-Not($?)) {
        Return
    }

    java $filenameParts[0]
}
