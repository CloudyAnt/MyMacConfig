# git related
alias glog='git log --oneline'
alias gamd='git commit --amend'
alias gamdn='git commit --amend --no-edit'
alias gaap='git add -p'
## offical
# gaa = git add --A
# gst = git status
# gss = git status -s
# gco = git checkout

gctCommitTypes=(refactor fix feat chore doc test style)
gctCommitTypesTip=`echo $gctCommitTypes | awk '{for (i = 1; i <= NF; i++) { printf " \033[1;3" i "m" i ":" $i }} END{printf "\033[0m"}'`

function gpr() { #? git pull --rebase
    git pull --rebase
}
function gaaf() {
    [ -z $1 ] && return
    git add "*$1*"
}

function gcto() { #? commit in one line
    echo commit with message '"['$1']' $2: $3'" ? (y for Yes)'
    read oneline_commit
    [ "$oneline_commit" = "y" ] && gaa && git commit -m "[$1] $2: $3"
    unset oneline_commit
}

function gct() { #? commit in process
    [ ! -d `pwd`/.git ] && echo "Not a git repository!" && return
    
    needToCommit=`gst | awk '/Changes to be committed/{print 1}'`
    [ -z $needToCommit ] && echo "Nothing to commit!" && return

    git_commit_info_cache_folder=$Qfig_loc/.gcache
    preset_working_directory_cache=$git_commit_info_cache_folder/`pwd | sed 's|/|_|g'`.tmp

    [ ! -d "$git_commit_info_cache_folder" ] && mkdir $git_commit_info_cache_folder

    # read info if cache exist, use default if not
    info_separator="!@#!@#!@#"

    if [ -f "$preset_working_directory_cache" ]
    then
        eval `cat $preset_working_directory_cache | awk  -F $info_separator '{print "commit_name0=" $1 ";commit_number0=" $2 ";commit_type0=" $3 ";commit_desc0=" $4}'`
    fi

    defaultV commit_name0 "Unknown"
    defaultV commit_number0 "N/A"
    defaultV commit_type0 "other"
    defaultV commit_desc0 "Unknown"

    echo "[1/4] Name? ($commit_name0)"
    read commit_name
    echo "[2/4] Card? ($commit_number0)"
    read commit_number
    echo "[3/4] Type? ($commit_type0) |$gctCommitTypesTip"
    read commit_type

    if echo $commit_type | egrep -q '^[0-9]+$' && [ $commit_type -gt 0 ] && [ $commit_type -le ${#gctCommitTypes} ]
    then
        echo "\033[1;3${commit_type}m$gctCommitTypes[$commit_type]\033[0m"
        commit_type=$gctCommitTypes[$commit_type]   
    fi

    echo "[4/4] Note? ($commit_desc0)"
    read commit_desc

    defaultV commit_name $commit_name0
    defaultV commit_number $commit_number0
    defaultV commit_type $commit_type0
    defaultV commit_desc $commit_desc0

    # cache new info
    echo "'$commit_name'$info_separator'$commit_number'$info_separator'$commit_type'$info_separator'$commit_desc'" > $preset_working_directory_cache

    # commit
    full_commit_message="$commit_name [$commit_number] $commit_type: $commit_desc"
    git commit -m "$full_commit_message"

    # unset variables
    unset preset_working_directory
    unset preset_working_directory_cache
    unset commit_name0
    unset commit_number0
    unset commit_type0
    unset commit_desc0
    unset info_separator
    unset commit_name
    unset commit_number
    unset commit_type
    unset commit_desc
    unset full_commit_message
}

function gstash() { #? = git stash
    [ -z "$1" ] && git stash && return
    git stash push -m "git_stash_name_$1"
}

function gpop() { #? = git stash pop
    [ -z "$1" ] && git pop && return
    git stash apply $(git stash list | grep "git_stash_name_$1" | cut -d: -f1)
}

function gcst() { #? check multi folder commit status
    [ -z "$1" ] && gcst0 `pwd` && return
    present_directory=`pwd`
    for file in $1/* ; do
        gcst0 $file -p
    done
    cd $present_directory
}

function gcst0() { #? check single folder commit status
    [[ ! -d "$1" || ! -d "$1/.git" ]] && return
    cd $1
    [ "-p" = "$2" ] && echo $file | awk -F '/' '{print "\033[1;34m" $NF ":\033[0m" }'
    git status | awk '/Your branch is/{print}' | awk '{sub("Your branch is ", "")} 1' \
        | awk '{sub("up to date", "\033[1;32mUP TO DATE\033[0m")} 1' \
        | awk '{sub("ahead", "\033[1;31mAHEAD\033[0m")} 1' 
}

function remove_idea_bad_git_track() { #! do not use if unnecessary
    # include idea, .idea, *.iml, build, target, out 
    echo -e "# idea\n.idea\n*.iml\n\n# build\nbuild\ntarget\nout" >> .gitignore
    git add .gitignore
    git rm -r --cached .idea > /dev/null 2>&1
    git rm -r --cached build > /dev/null 2>&1
    git rm -r --cached target > /dev/null 2>&1
    git rm -r --cached out > /dev/null 2>&1
    git rm --cached *.iml > /dev/null 2>&1
}
