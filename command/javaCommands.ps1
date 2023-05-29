#? These are commands about java, make sure it's available before use.

function jrun() { #? java compile then run, jrun Hello => javac Hello.java && java Hello
    param(
        [Parameter(Mandatory)]$file
    )

    $filenameParts = $file.split(".")
    If ($filenameParts.Length -Eq 2 -And $filenameParts[1].Equals("java")) {
    } Elseif ($filenameParts.Length -Eq 1) {
        $file = $file + ".java"
    }

    If (-Not(Test-Path $file)) {
        logError "File doesn't exist !"
        Return
    }

    javac $file

    # return if javac failed
    If (-Not($?)) {
        Return
    }

    java $filenameParts[0]
}
