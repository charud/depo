#!/bin/sh
# @name Depo
# @description A shellscript for deploying node.js applications on a remote server using git and virtualhosts
# @author Charlie Rudenstål <charlie4@gmail.com>
#
# Place this script on the client
#
# Creates a new virtualhost setting and checkouts the repository using GIT
#     $ depo create [nameOfVirtualHost] [repository] [optional branch]    
#
# Updates the git repository to HEAD (Will remove all local modifications, this is not a merge)
#     $ depo update [nameOfVirtualHost]
#
# Show a list of all virtual hosts, folders, associated git repository urls and current branches
# on the remote server. 
#     $ depo list
#
# Restart the proxy server (using forever). Will start it if not already running.
#     $ depo restart
#
#
# Configuration
# =============
# Remote Host
# Change to your remote server host (will connect using SSH)
REMOTE_HOST=johndoe@example.org

# Remote path proxy server
# Will look for server.js (and create a server.js.tmp during the process)
# Must end with /
REMOTE_PATH_TO_PROXY_SERVER=/home/DepoProxy/

# Remote path to public html
# Will create folders for each site in here and look for server.js or other start point defined in package.json
# Must end with /
REMOTE_PATH_TO_PUBLIC_HTML=/home/public_html/


if [ $# -lt 1 ]; then
	echo "Usage: depo {create|update|list|restart}"
	exit 2;
fi

case $1 in
	create)

		if [ $# -lt 2 ]; then
			echo "Missing nameOfVirtualHost";
			echo "Usage: depo $1 nameOfVirtualHost gitRepositoryUrl [branch]";
			exit 2;
		fi

		PARAM_VIRTUALHOST_NAME=$2

		if [ $# -lt 3 ]; then
			echo "Missing gitRepositoryUrl"
			echo "Usage: depo $1 nameOfVirtualHost gitRepositoryUrl [branch]";
			exit 2;
		fi

		PARAM_GIT_REPOSITORY_URL=$3

		if [ $# -lt 3 ]; then
			echo "Creating virtualhost for $PARAM_VIRTUALHOST_NAME using repository $PARAM_GIT_REPOSITORY_URL"
		fi

		PARAM_BRANCH="master"

		if [ $# -gt 3 ]; then
			PARAM_BRANCH=$4
			echo "Creating virtualhost for $PARAM_VIRTUALHOST_NAME using repository $PARAM_GIT_REPOSITORY_URL and branch $PARAM_BRANCH"
		fi

		ssh -T $REMOTE_HOST <<EOI
		
		echo
		echo Creating virtual host...
		echo ========================
		echo 
 		cd $REMOTE_PATH_TO_PROXY_SERVER
		sed -e '\$d' server.js > server.tmp.js
		echo 'app.use(express.vhost('\''$PARAM_VIRTUALHOST_NAME'\'', require('\''$REMOTE_PATH_TO_PUBLIC_HTML$PARAM_VIRTUALHOST_NAME'\'').app));' >> server.tmp.js
		cp server.tmp.js server.js
		rm server.tmp.js
		echo 'app.listen(8080);' >> server.js
		
		echo
		echo Checking out repository...
		echo ==========================
		echo 

		cd $REMOTE_PATH_TO_PUBLIC_HTML
		mkdir $PARAM_VIRTUALHOST_NAME
		cd $PARAM_VIRTUALHOST_NAME
		git init
		git remote add -f origin $PARAM_GIT_REPOSITORY_URL
		git checkout $PARAM_BRANCH

		echo
		echo Restaring proxy server...
		echo =========================
		echo
		
		cd $REMOTE_PATH_TO_PROXY_SERVER
		forever stop server.js
		forever start server.js
		exit
EOI
	;;

	update)
	
		if [ $# -lt 2 ]; then
			echo "Usage: depo $1 nameOfVirtualHost";
			exit 2;
		fi
		
		PARAM_VIRTUALHOST_NAME=$2

		ssh -T $REMOTE_HOST <<EOI

		echo
		echo Updating repository...
		echo ======================
		echo

		cd $REMOTE_PATH_TO_PUBLIC_HTML
		cd $PARAM_VIRTUALHOST_NAME
		git reset --hard HEAD
		git clean -f -d
		git pull

		echo
		echo Restaring proxy server...
		echo =========================
		echo

		cd $REMOTE_PATH_TO_PROXY_SERVER
		forever stop server.js
		forever start server.js
		exit
EOI
	;;

	restart)
		ssh -T $REMOTE_HOST <<EOI

		echo
		echo Restaring proxy server...
		echo =========================
		echo

		cd $REMOTE_PATH_TO_PROXY_SERVER
		forever stop server.js
		forever start server.js
		exit
EOI
	;;

	list)
		ssh -T $REMOTE_HOST <<EOI

		echo
		echo Configured virtual hosts
		echo ========================
		
		cd $REMOTE_PATH_TO_PROXY_SERVER
		cat server.js | grep vhost
		
		echo
		echo Folders and Git repositories 
		echo ============================
		
		cd $REMOTE_PATH_TO_PUBLIC_HTML		
		printf "%25s %25s\n" Folder Repo
		for dir in */; do
			REPO_URL=\`git --git-dir \${dir}.git config --get remote.origin.url 2> /dev/null \`
			if [ -z \$REPO_URL ]; then continue; fi
			REPO_BRANCH=\`git --git-dir \${dir}.git branch 2> /dev/null | sed -n -e 's/^\* \(.*\)/\1/p'\`
			printf "%25s %s @ %s\n" \$dir \$REPO_URL \$REPO_BRANCH				
		done

		echo \$OUTPUT_LIST

		exit
EOI
	;;

*)
	echo "Usage: depo {create|update|list|restart}"
esac