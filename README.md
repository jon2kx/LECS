# LECS
Linux (RPM) Environment Compliance Script

You need to customize the script for your environments.

Mandatory customizations:

	Customize ProfileDirectory
	Customize STDOUTDirectory
	Customize TITLE
	Customize MENU
	Customize BACKTITLE
	Customize PubKeyDir
	Customize PubKey
	Customize SSHUID
	Customize SSH_Action()

Optional Customizations:

	CUSTENVPatchEvalFile
	CUSTENVPatchEvalFileOpt

This is a template based system with profiles, you can create profiles and store them in the ProfileDirectory with following options:

	CUSTHOSTS="host1 host2 host3"
	ENV="tst"
	FQDN="client.hosting.com"
	CLIENT="dundermifflin"

