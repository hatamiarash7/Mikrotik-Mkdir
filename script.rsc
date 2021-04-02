:log info "Creating \$mkdir function..."

:global mkdir do={
    :local newFolder $1;

    :if ([/file find name=$newFolder] != "") do={
        :log debug "mkdir: '$newFolder' already exists.";
        :error "'$newFolder' already exists.";
    }

    :local tempfile "mkdir_temp_file.txt";

    :local mkdirRule "mkdir_temp_rule"

    /system clock print file=$tempfile;

    :local tempuser "__dircreate";

    :local passwd [:tostr ([/system resource get cpu-load] . [/system identity get name] . [/system resource get free-memory])];

    :local isFTPDisabled [/ip service get ftp disabled];

    :local oldFTPAddr [/ip service get ftp address];

    :local errorMsg

    :while (([:pick $newFolder ([:len $newFolder] - 1)]) = "/") do={
        :set newFolder [:pick $newFolder 0 ([:len $newFolder] - 1)]
    }

    :while ([:pick $newFolder 0] = "/") do={
        :set newFolder [:pick $newFolder 1 [:len $newFolder]]
    }

    :if ([/user find name=$tempuser] != "") do={
        /user remove $tempuser;
    }
    :if ([/user group find name=$tempuser] != "") do={
        /user group remove $tempuser;
    }

    /user group add name=$tempuser policy=ftp,read,write comment="temporary group for mkdir function";

    /user add name=$tempuser group=$tempuser address=127.0.0.1/32 comment="temporary user for mkdir function" password=$passwd disabled=no;

    :local newFTPAllowList
    :if ($isFTPDisabled) do={
        :set newFTPAllowList 127.0.0.1
    } else={
        :if ($oldFTPAddr = "") do={
            :set newFTPAllowList [/ip service get ftp address]
        } else={
            :set newFTPAllowList ([/ip service get ftp address],127.0.0.1)
        }
    }

    /ip service set ftp disabled=no address=$newFTPAllowList;

    :do {
        :local count 0;
        :while ([/file find name=$tempfile] = "") do={
            :if ($count >= 100) do={
                :set errorMsg "Couldn't create a temp file"
                :error $errorMsg
            }
            :delay 0.05s;
            :set count ($count + 1);
        }
        
        /file set $tempfile contents=""
        
        :do {
            :local ftpPort [/ip service get ftp port];
            :do { /ip firewall filter add action=accept chain=input comment=$mkdirRule dst-address=127.0.0.1 in-interface-list=!all port=$ftpPort protocol=tcp src-address=127.0.0.1 place-before=0 } on-error={}
            :do { 
                /ip firewall mangle
                add action=accept chain=prerouting comment=$mkdirRule dst-address=127.0.0.1 in-interface-list=!all port=$ftpPort protocol=tcp src-address=127.0.0.1 place-before=0
                add action=fasttrack-connection chain=prerouting comment=$mkdirRule dst-address=127.0.0.1 in-interface-list=!all port=$ftpPort protocol=tcp src-address=127.0.0.1 place-before=0
            } on-error={}
            :do { /ip firewall nat add action=accept chain=srcnat comment=$mkdirRule dst-address=127.0.0.1 out-interface-list=!all port=$ftpPort protocol=tcp src-address=127.0.0.1 place-before=0 } on-error={}
            :do { /ip firewall raw add action=accept chain=prerouting comment=$mkdirRule dst-address=127.0.0.1 in-interface-list=!all port=$ftpPort protocol=tcp src-address=127.0.0.1 place-before=0 } on-error={}
            /tool fetch address=127.0.0.1 port=$ftpPort mode=ftp user=$tempuser password=$passwd src-path=$tempfile dst-path="$newFolder/$tempfile";
        } on-error={
            :set errorMsg "Failed to create folder $newFolder";
            :error $errorMsg;
        }

    } on-error={
        :log error "mkdir: $errorMsg";
        :put $errorMsg
    }

    # Clean up

    :do { /ip service set ftp disabled=$isFTPDisabled address=$oldFTPAddr; } on-error={}
    :do { /user remove $tempuser; } on-error={}
    :do { /user group remove $tempuser; } on-error={}
    :do { /file remove $tempfile; } on-error={}

    :local count 0;
    :while ([/file find name="$newFolder/$tempfile"] = "") do={
        :if ($count >= 20) do={
            :set errorMsg "Couldn't delete $newFolder/$tempFile"
            :log error "mkdir: $errorMsg"
            :error $errorMsg
        }
        :delay 0.1s;
        :set count ($count + 1);
    }

    :do { /file remove "$newFolder/$tempfile"; } on-error={}
    :do { /ip firewall filter remove [find comment=$mkdirRule] } on-error={}
    :do { /ip firewall mangle remove [find comment=$mkdirRule] } on-error={}
    :do { /ip firewall nat remove [find comment=$mkdirRule] } on-error={}
    :do { /ip firewall raw remove [find comment=$mkdirRule] } on-error={}
}

:log info "Created function \$mkdir"
