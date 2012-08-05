Depo
====
A shellscript for deploying node.js applications on a remote server using ssh, git and virtualhosts. When doing updates with this script the server copy of the repository will be reset to HEAD.

Installation
------------
#### On your server
Put the folder ``DepoProxy`` somewhere on your server, enter the folder and run ``npm install`` to install its dependencies (currently express). Make sure that your SSH user can access this folder. You also need to install ``forever`` from https://github.com/nodejitsu/forever/

#### On your client
Place depo.sh on a client from where you would like to manage the deployments:

	$ wget https://raw.github.com/charlie-rudenstal/depo/master/depo.sh
	$ chmod +x depo.sh

Then open depo.sh in your favorite editor and configure the variables
* __REMOTE\_HOST__  
  Change to your remote server host (will connect using SSH)

* __REMOTE\_PATH\_TO\_PROXY\_SERVER__  
  Will look for server.js (and create a server.js.tmp during the process). Must end with /

* __REMOTE\_PATH\_TO\_PUBLIC\_HTML__  
  Folders for each site will be created at this path. DepoProxy and look for a start script such as server.js.

For easier access when you are working on your projects, copy it to /usr/bin without the .sh extension and mark it as executable 
	
	$ sudo cp depo.sh /usr/bin/depo
	$ sudo chmod +x /usr/bin/depo

Usage
-----
- __depo create__ [nameOfVirtualHost] [repository] [optional branch]  
  Setup a new virtualhost on the server and checkout the specified repository using git

	```bash
	$ depo create beta.example.org https://github.com/john-doe/example beta    
	```

- __depo update__ [nameOfVirtualHost]  
  Update the repository for the selected virtualhost on the server. (Reset to HEAD) 
  This will remove possible local modifications in the server repository, it is not a merge.

		$ depo update beta.example.org

- __depo list__  
  Show a list of all virtual hosts, folders, associated git repository urls and current branches on the remote server. 

		$ depo list

- __depo restart__  
  Restart the proxy server (using forever). Will start it if not already running.
	
		$ depo restart


How it works
-----------------------

#### depo.sh

depo.sh will access your server using SSH. It will modify the file ``server.js`` located at
the server path you specify for DepoProxy (``__REMOTE\_PATH\_TO\_PROXY\_SERVER__``). It will also create new folders in the path ``_REMOTE\_PATH\_TO\_PUBLIC\_HTML`` and checkout a clone of the
git repository you supply. 

When running the ``list`` command it will return the virtual hosts defined in ``server.js``, traverse the directory ``_REMOTE\_PATH\_TO\_PUBLIC\_HTML`` and retrieve the current repository url and branch for each directory inside, using git.  

#### Virtualhosts with DepoProxy

When adding new virtual hosts using ``depo create`` depo.sh will connect to your server and re-generate the ``server.js`` at ``__REMOTE\_PATH\_TO\_PROXY\_SERVER__``. When a new virtualhost is added it will: 

 1.  Remove the last line of server.js (app.listen()), 
 2.  Append a new app.use() statement
 3.  Append app.listen() again *

Virtual hosts that depo.sh generates looks something like this:

```js
app.use(express.vhost('beta.example.org', require('/home/cr/beta.example.org').app));
```

You may modify server.js as you see fit, but be sure to leave no newlines at the end of the file.


Author  
Charlie Rudenstål  
<charlie4@gmail.com>