<cfapplication name="gravatarcache">

<cfparam name="url.profile" default="default">
<cfparam name="url.gravatar_id">

<cfif not structKeyExists(application, "settings") or structKeyExists(url, "ginit") or 1>
	<!--- Load settings --->
	<cfset settings = structNew()>
	<cfset thisFolder = expandPath(".")>
	<cfset settingsXML = xmlParse("#thisFolder#/settings.xml")>

	<cfloop index="x" from="1" to="#arrayLen(settingsXML.settings.profile)#">
		<cfset profile = settingsXML.settings.profile[x]>
		<cfset name = profile.xmlAttributes.name>
		<cfset thisSetting = structNew()>

		<cfloop item="setting" collection="#profile#">
			<cfset thisSetting[setting] = profile[setting].xmlText>
		</cfloop>
		<!--- used for binary cache of default image --->
		<cfset thisSetting.defaultBinary = "">
		<cfset settings[name] = thisSetting>
	</cfloop>
	
	
	<cfset application.settings = settings>
</cfif>

<!--- what is the current profile? Copied to local scope just for easiness --->
<cfset profile = url.profile>

<cfif not structKeyExists(application.settings, profile)>
	<cfthrow message="Invalid profile [#profile#] passed.">
<cfelse>
	<cfset settings = application.settings[profile]>
</cfif>

<!--- Check if folder exists --->
<cfset cacheFolder = expandPath(".") & "/" & settings.cachedir & "/">

<cfif not directoryExists(cacheFolder)>
	<cfdirectory action="create" directory="#cacheFolder#">
</cfif>

<!--- The image requested, translated into a file name --->
<cfset image = url.gravatar_id & ".png">

<!--- Check if cached image exists and compare the date --->
<cfif fileExists(cacheFolder &  image)>
	<!--- get last mod --->
	<cfdirectory directory="#cacheFolder#" filter="#image#" name="imageInfo">
	<cfset lastUpdated = imageInfo.dateLastModified>
	<cfif dateDiff("n", lastUpdated, now()) lte settings.cachetimeout>
		<cfcontent type="image/png" file="#cacheFolder##image#">
		<cfabort>
	</cfif>
</cfif>

<!--- We only get here if we didn't have a valid cached image --->
<cfset link = "http://www.gravatar.com/avatar.php?gravatar_id=#url.gravatar_id#&rating=#settings.rating#&size=#settings.size#&border=#settings.border#">
<!--- Append default if we have it --->
<cfif structKeyExists(settings, "default")>
	<cfset link = link & "&default=#urlEncodedFormat(settings.default)#">
</cfif>
<cfhttp url="#link#" timeout="#settings.timeout#" getAsBinary="yes" result="result">

<!--- was it a good download? --->
<cfif structKeyExists(result.responseheader, "status_code") and result.responseheader.status_code is "200">
	<!--- save the result to the file system --->
	<cffile action="write" file="#cacheFolder##image#" output="#result.fileContent#">
	<cfcontent type="image/png" file="#cacheFolder##image#">
	<cfabort>
<cfelse>
	<!--- bad result, so use default image if exists --->
	<!--- Note that we also asked Gravatar for the default, but it may time out. --->
	<cfif structKeyExists(settings, "default")>
		<cfif not len(settings.defaultBinary)>
			<!--- Same logic as before, suck it down and store it --->
			<cfhttp url="#settings.default#" result="defaultResult" getAsBinary="yes">
			<cfif structKeyExists(defaultResult.responseheader, "status_code") and defaultResult.responseheader.status_code is "200">
				<cfset settings.defaultBinary = defaultResult.fileContent>
			</cfif>
		</cfif>
		<cfif len(settings.defaultBinary)>
			<cffile action="write" file="#cacheFolder##image#" output="#settings.defaultBinary#">
			<cfcontent type="image/png" file="#cacheFolder##image#">
			<cfabort>		
		</cfif>
	</cfif>	
</cfif>
