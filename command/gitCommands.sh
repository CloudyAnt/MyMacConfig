#? Git related

alias g-='gco -'
alias gaa='git add -A'
alias gaap='git add -p'
alias gamd='git commit --amend'
alias gamdn='git commit --amend --no-edit'
alias gco='git checkout'
alias gcpa='git cherry-pick --abort'
alias gcpc='git cherry-pick --continue'
alias glist='git stash list --date=local'
alias glistp='git stash list --pretty=format:"%C(red)%h%C(reset) - %C(dim yellow)(%C(bold magenta)%gd%C(dim yellow))%C(reset) %<(70,trunc)%s %C(green)(%cr) %C(bold blue)<%an>%C(reset)"'
alias glo='git log --oneline'
alias glog='git log --oneline --abbrev-commit --graph'
alias gmg-='git merge -'
alias gmga='git merge --abort'
alias gmgc='git merge --continue'
alias gpr='git pull --rebase'
alias grb-='git rebase -'
alias grba='git rebase --abort'
alias grbc='git rebase --continue'
alias grmc='git rm --cached'
alias gst='git status'
alias gss='git status -s'
forbidAlias gp gpush "git push"
forbidAlias gl "git pull"
forbidAlias gc gct "git commit"
forbidAlias gap gapply

function gtag() { #? operate tag. Usage: gtag $tag(optional) $cmd(optional) $cmdArg(optional). gtag -h for more
	if [ -z $1 ]; then
		git tag --points-at # --points-at defaults to HEAD
	elif [ "-h" = "$1" ]; then
		logInfo "Usage: gtag \$tag(optional) \$cmd(optional) \$cmdArg(optional).\n  If no params specified, then show the tags for current commit\n  Available commands:\n"
		printf "    %-17s%s\n" "c/create" "Default. Create a tag on current commit."
		printf "    %-17s%s\n" "p/push" "Push the tag to remote, use the 3rd param to specify the remote tag name"
		printf "    %-17s%s\n" "d/delete" "Delete the tag"
		printf "    %-17s%s\n" "dr/delete-remote" "Delete the remote tag, \$tag is the remote tag name here"
		return
	elif [[ $1 = -* ]]; then
		logError "A Tag should not starts with '-'" && return 1
	else
		local cmd=$2
		if [ -z $cmd ]; then
			cmd="c"
		fi
		case $cmd in
			c|create)
				git tag $1
				if [ 0 -eq $? ]; then
					logSuccess "Created tag: $1"
				fi
			;;
			p|push)
				git push origin $1 $3
			;;
			d|delete)
				git tag -d $1
			;;
			dr|delete-remote)
				git push origin :refs/tags/$1
			;;
			*)
				logError "Unknown command: $cmd"
				gtag -h
				return 1
			;;
		esac
	fi
}

function gaaf() { #? git add files in pattern
    [ -z $1 ] && return
    git add "*$1*"
}

function gbco() { #? git branch foo && git checkout foo
    [ -z $1 ] && return
	git branch $1
	git checkout $1
}

function gctm() { #? commit with message
	if [ "$1" = '' ]
	then 
		logWarn "Commit without message?"
		qread confirm
		[ "$confirm" = "y" ] && gaa && git commit -m "" 
	else
		gaa
		git commit -m "$1"
	fi
}

function gcto() { #? commit in one line
    echo commit with message '"['$1']' $2: $3'" ? (y for Yes)'
    qread oneline_commit
    [ "$oneline_commit" = "y" ] && gaa && git commit -m "[$1] $2: $3"
    unset oneline_commit
}

_git_stash_key="_git_stash_:"

function gstash() { #? stash with specific name. Usage: gstash name(optional)
    if [ -z "$1" ] 
    then
        git stash
        return
    fi
    git stash push -m "$_git_stash_key""$1" # stash with specific name
}

function gstashu() { #? stash unstaged files with specific name. Usage: gstashu name(optional)
    if [ -z "$1" ] 
    then
        git stash --keep-index
        return
    fi
    git stash push -m "$_git_stash_key""$1" --keep-index # stash with specific name
}

function gapply() { #? apply with specific name. Usage: gapply name(optional)
    if [ -z "$1" ] 
    then
        git stash apply
        return
    fi
    local key=$(git stash list | grep "$_git_stash_key""$1" | cut -d: -f1)
    [ -z "$key" ] && logWarn "The stash key \"$1\" doesn't exist!" && return
    git stash apply $key # apply with specific name
}

function gpop() { #? pop with specific name. Usage: gpop name(optional)
    if [ -z "$1" ] 
    then
        git stash pop
        return
    fi
    local key=$(git stash list | grep "$_git_stash_key""$1" | cut -d: -f1)
    [ -z "$key" ] && logWarn "The stash key \"$1\" doesn't exist!" && return
    git stash pop $key # pop with specific name
}

function gcst() { #? check multi folder commit status
	function gcst0() {
		[[ ! -d "$1" || ! -d "$1/.git" ]] && return
		[ "-p" = "$2" ] && echo $1 | awk -F '/' '{print "\033[1;34m" $NF ":\033[0m" }'
		git -C $1 status | awk '/Your branch is/{print}' | awk '{sub("Your branch is ", "")} 1' \
			| awk '{sub("up to date", "\033[1;32mUP TO DATE\033[0m")} 1' \
			| awk '{sub("ahead", "\033[1;31mAHEAD\033[0m")} 1' 
	}

    local folder=$1
	if [ -z $folder ]; then
		gcst0 $(pwd)
	else
		local file
		for file in $folder/* ; do
			gcst0 $file -p
		done
	fi

	unset -f gcst0
}

function ghttpproxy() { #? Usage: gttpproxy proxy. unsert proxy if 'proxy' is empty
    if [ -z "$1" ]
    then
        git config --global --unset http.proxy
        git config --global --unset https.proxy
        logSuccess "Clean git http/https proxy"
    else
        git config --global http.proxy $1
        git config --global https.proxy $1
        logSuccess "Set git http/https proxy as $1"
    fi
}

function gpush() { #? git push with automatic branch creation
    [ ! "`git rev-parse --is-inside-work-tree 2>&1`" = 'true' ] && logError "Not a git repository!" && return 1
	logInfo "Push starting.."
	local message=$(git push 2>&1 | tee /dev/tty)
	if [[ $message = *"has no upstream branch"* ]]; then
		logInfo "'No upstream branch' was told, creating"
		local branch=$(git rev-parse --abbrev-ref HEAD)
		local message=$(git push -u origin $branch)
		if [ $? = 0 ]; then
			logSuccess "Upstream branch just created"
		else
			logError "Failed to create upstream branch \e[1m$branch\e[0m"
		fi
	elif [[ $message = *"fatal"* || $message = *"error"* ]]; then
		logWarn "Push seems failed, check the above message"
	else
		logSuccess "Push done"
	fi
}

function gtop() { #? go to the top level of current repo
    # CHECK if this is a git repository
    [ ! "`git rev-parse --is-inside-work-tree 2>&1`" = 'true' ] && logError "Not a git repository!" && return 1
	local gitTopLevel=$(git rev-parse --show-toplevel)
	logInfo "Go to:\n$gitTopLevel"
	cd $gitTopLevel
}

function gct() { #? git commit step by step
	# READ flags
	local setPattern=""
	local verbose=""
	while getopts "phv" opt; do
		case $opt in
			h)
				logInfo "A command to git-commit step by step\n\n  Available flags:"
				printf "    %-6s%s\n" "-h" "Print this help message and return"
				printf "    %-6s%s\n" "-p" "Specify the pattern"
				printf "    %-6s%s\n" "-v" "Show more verbose info"
				echo
				echo "  \e[34;1mPattern Hint\e[0m:\n  Example: \e[34m<step1:default> <#step2:default option2 option3>: <step3@[^\\:]+>\e[0m. \
The \e[1m#\e[0m in step2 behind char \e[1m<\e[0m indicate it's a branch-scope-step. \
The \e[1m[^\\:]+\e[0m in step3 behind char \e[1m@\e[0m sepcify the regex this step value must match. \e[1m\ \e[0mescape the character behind it.\n"
				echo "  \e[34;1mCommit Hint\e[0m:\n  Input then press \e[1mEnter\e[0m to set value for a step, \e[34mthe last-time value or default value will be appended\e[0m if the input is empty. \
You can also \e[34mchoose one option by input number\e[0m if there are multi options specified for current step.\n"
				echo "  Recommend pattern: $(cat $Qfig_loc/staff/defGctPattern)"
				return
				;;
			p) # specify pattern
				setPattern=1
				;;
			v) # display verbose infos
				verbose=1
				;;
			\?)
				logError "Invalid option: -$OPTARG" && return 1
				;;
		esac
	done

    # CHECK if this is a git repository
    [ ! "`git rev-parse --is-inside-work-tree 2>&1`" = 'true' ] && logError "Not a git repository!" && return 1
    # CHECK if merge, rebase, cherry-pick or revert is in progress 
	local gitStatus=$(git status 2>&1)
	local obstacleProgress=""
	if [[ "$gitStatus" = *"All conflicts fixed but you are still merging"* || "$gitStatus" = *"You have unmerged paths"* ]]; then
		obstacleProgress=Merge
	elif [[ "$gitStatus" = *"interactive rebase in progress;"* ]]; then
		obstacleProgress=Rebase
	elif [[ "$gitStatus" = *"You are currently cherry-picking"* ]]; then
		obstacleProgress=Cherry-pick
	elif [[ "$gitStatus" = *"You are currently reverting"* ]]; then
		obstacleProgress=Revert
	fi
	if [ $obstacleProgress ]; then
		logWarn "$obstacleProgress in progress, continue ? \e[90mY for Yes, others for No.\e[0m" "!"
		qread yn
		if ! [[ 'y' = "$yn" || 'Y' = "$yn" ]]; then
			return 0	
		fi
	fi

    # GET pattern & cache, use default if it not exists
	local git_toplevel=$(git rev-parse --show-toplevel)
    local git_commit_info_cache_folder=$Qfig_loc/.gcache/$(echo $git_toplevel | md5)
	[ ! -d "$git_commit_info_cache_folder" ] && mkdir -p $git_commit_info_cache_folder
	local pattern_tokens_file=$git_commit_info_cache_folder/pts
	local r_step_values_cache_file=$git_commit_info_cache_folder/rsvc # r = repository
	local b_step_values_cache_file=$git_commit_info_cache_folder/bsvc-$(git branch --show-current) # b = branch

	# SET pattern
	local repoPattern=".gctpattern"
	local boldRepoPattern="\e[1m$repoPattern\e[0m"
	local gctpattern_file=$git_toplevel/$repoPattern
	local saveToRepo=""
	if [ -f "$gctpattern_file" ]; then
		[ $setPattern ] && logError "Can not specify pattern when $boldRepoPattern exists, modify it to achieve this" && return 1

		# read from .gctpattern
		local pattern=$(cat $gctpattern_file)
		[ $verbose ] && logSilence "Using $boldRepoPattern \e[90mpattern: $pattern"
		[ -f "$pattern_tokens_file" ] && [ "?:$pattern" = "$(head -n 1 $pattern_tokens_file)" ] || setPattern=1
	else
		if [ $setPattern ]; then
			# specify local pattern
			logInfo "Please specify the pattern(Rerun with -h to get hint):"
			qread pattern
		elif [ ! -f "$pattern_tokens_file" ]; then
			setPattern=1
			logInfo "Use default pattern \e[34;3;38m$(cat $Qfig_loc/staff/defGctPattern)\e[0m ? \e[90mY for Yes, others for No.\e[0m" "?"
			qread yn
			if [[ 'y' = "$yn" || 'Y' = "$yn" ]]; then
				logInfo "Using default pattern"
				pattern=$(cat $Qfig_loc/staff/defGctPattern)
			else
				logInfo "Then please specify the pattern(Rerun with -p to change, -h to get hint):"
				qread pattern
			fi
		elif [ $verbose ]; then
			logSilence "Using local pattern: ${$(head -n 1 $pattern_tokens_file):2}"
		fi
		#if [ $setPattern ]; then # whether save to .gctpattern
			# logInfo "Save it in $boldRepoPattern(It may be shared through your git repo) ? \e[90mY for Yes, others for No.\e[0m" "?"
			# qread saveToRepo
		#fi
	fi

	# RESOLVE pattern
	if [ $setPattern ]; then
		resolveResult=$($Qfig_loc/staff/resolveGctPattern.sh $pattern)
		if [ $? -eq 0 ]; then
			echo "?:$pattern" > $pattern_tokens_file
			echo $resolveResult >> $pattern_tokens_file
			[ -f "$r_step_values_cache_file" ] && rm $r_step_values_cache_file
			[ -f "$b_step_values_cache_file" ] && rm $b_step_values_cache_file
			# [[ 'y' = "$saveToRepo" || 'Y' = "$saveToRepo" ]] && echo $pattern > $gctpattern_file && logInfo "Pattern saved in $boldRepoPattern"
			logSuccess "New pattern resolved!"
		else
			logError "Invalid pattern: $resolveResult" && return 1
		fi
	fi

    # CHECK if it's need to commit
    local needToCommit=`gst | awk '/Changes to be committed/{print 1}'`
    [ -z $needToCommit ] && logWarn "Nothing to commit!" && return 1

	# GET pattern tokens
	local tokens
	IFS=$'\n' tokens=($(cat $pattern_tokens_file)) IFS=' '

	stepsCount=0
	for t in ${tokens[@]}; do
		if [[ "$t" = 1:* ]]; then
			stepsCount=$((stepsCount + 1))	
		fi
	done
	
	# APPEND message step by step
	local message=""
	local curStepNum=0
	local rCurStepNum=0
	local bCurStepNum=0 # branch scope step count
	local rStepValues
	local bStepValues
	[ -f $r_step_values_cache_file ] && IFS=$'\n' rStepValues=($(cat $r_step_values_cache_file)) IFS=' ' || rStepValues=()
	[ -f $b_step_values_cache_file ] && IFS=$'\n' bStepValues=($(cat $b_step_values_cache_file)) IFS=' ' || bStepValues=()
	local newRStepValues=""
	local newBStepValues=""
	local stepKey=""
	local stepRegex=""
	local stepOptions=""
	local proceedStep=0
	local branchScope=0
	local stepPrompt
	local stepDefValue
	local partial
	for ((i=1; i<=${#tokens[@]}; i++)); do
		t=$tokens[$i]
		case $t in
			0:*)
				message+=${t:2}
				stepKey=""
			;;
			1:*)
				stepKey=${t:2}
				if ! [[ $tokens[$((i + 1))] =~ 11:* || $tokens[$((i + 1))] =~ 12:* ]]; then
					proceedStep=1
				fi
			;;
			10:*)
				branchScope=1
			;;
			11:*)
				if [ $stepKey ]; then
					stepRegex=${t:3}
					if ! [[ $tokens[$((i + 1))] =~ 12* ]]; then
						proceedStep=1
					fi
				fi
			;;
			12:*)
				if [ $stepKey ]; then
					stepOptions=(${(@s/ /)${t:3}})
					proceedStep=1
				fi
			;;
		esac

		if [[ $proceedStep -eq 1 && ! -z $stepKey ]]; then
			curStepNum=$((curStepNum + 1))
			stepPrompt="\e[33m[$curStepNum/$stepsCount]\e[0m "

			if [ $branchScope -eq 1 ]; then
				bCurStepNum=$((bCurStepNum + 1))
				stepDefValue="${bStepValues[$bCurStepNum]:1}" # cached value start with '>'
				stepPrompt+="\e[4m$stepKey?\e[0m "
			else
				rCurStepNum=$((rCurStepNum + 1))
				stepDefValue="${rStepValues[$rCurStepNum]:1}" # cached value start with '>'
				stepPrompt+="$stepKey? "
			fi

			if [ $stepRegex ]; then
				stepPrompt+="\e[2m$stepRegex\e[22m "
			fi
			if [ ! -z "$stepOptions" ]; then
				[ -z "$stepDefValue" ] && stepDefValue=${stepOptions[1]}
				stepPrompt+="($stepDefValue) " 
				if [ 1 -lt "${#stepOptions[@]}" ]; then
					# append option id
					stepPrompt+="|$(echo $stepOptions | awk '{for (i = 1; i <= NF; i++) { if (i < 7) printf " \033[1;3" i "m" i ":" $i;
				else printf " \033[1;37m" i ":" $i;}} END{printf "\033[0m"}')"
				fi
			else
				[ ! -z "$stepDefValue" ] && stepPrompt+="($stepDefValue) " 
			fi
			echo "$stepPrompt"

			# READ and record value
			while
				qread partial
				if [ -z $partial ]; then
					partial=$stepDefValue
				elif [ 1 -lt "${#stepOptions[@]}" ]; then
					# select by option id
					if echo $partial | egrep -q '^[0-9]+$' && [ $partial -le ${#stepOptions} ]
					then
						echo "\e[2mChosen:\e[0m \e[1;3${partial}m$stepOptions[$partial]\e[0m"
						partial=$stepOptions[$partial]
					fi
				fi
				if [[ $partial && $stepRegex && ! $partial =~ $stepRegex ]]; then
					logWarn "Value not matching \e[1;31m$stepRegex\e[0m. Please re-enter:"
					true
				else
					false
				fi
			do :; done

			message+=$partial
			if [ $branchScope -eq 1 ]; then
				newBStepValues+=">$partial\n" # start width '>' to avoid empty line
			else
				newRStepValues+=">$partial\n" # start width '>' to avoid empty line
			fi

			# RESET step metas
			stepKey=""
			stepRegex=""
			stepOptions=""
			proceedStep=0
			branchScope=0
		fi
	done

	echo $newRStepValues > $r_step_values_cache_file
	echo $newBStepValues > $b_step_values_cache_file

	# COMMIT 
	git commit -m "$message"
}
