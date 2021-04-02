/system script remove [find name=mkdir_function];
/system script
add dont-require-permissions=no name=mkdir_function owner=admin \
    policy=ftp,reboot,read,write,policy,test,password,sniff,sensitive,romon \
    source=":log info \"Creating \\\$mkdir function...\"\r\
    \n\r\
    \n:global mkdir do={\r\
    \n    :local newFolder \$1;\r\
    \n\r\
    \n    :if ([/file find name=\$newFolder] != \"\") do={\r\
    \n        :log debug \"mkdir: '\$newFolder' already exists.\";\r\
    \n        :error \"'\$newFolder' already exists.\";\r\
    \n    }\r\
    \n\r\
    \n    :local tempfile \"mkdir_temp_file.txt\";\r\
    \n\r\
    \n    :local mkdirRule \"mkdir_temp_rule\"\r\
    \n\r\
    \n    /system clock print file=\$tempfile;\r\
    \n\r\
    \n    :local tempuser \"__dircreate\";\r\
    \n\r\
    \n    :local passwd [:tostr ([/system resource get cpu-load] . [/system id\
    entity get name] . [/system resource get free-memory])];\r\
    \n\r\
    \n    :local isFTPDisabled [/ip service get ftp disabled];\r\
    \n\r\
    \n    :local oldFTPAddr [/ip service get ftp address];\r\
    \n\r\
    \n    :local errorMsg\r\
    \n\r\
    \n    :while (([:pick \$newFolder ([:len \$newFolder] - 1)]) = \"/\") do={\
    \r\
    \n        :set newFolder [:pick \$newFolder 0 ([:len \$newFolder] - 1)]\r\
    \n    }\r\
    \n\r\
    \n    :while ([:pick \$newFolder 0] = \"/\") do={\r\
    \n        :set newFolder [:pick \$newFolder 1 [:len \$newFolder]]\r\
    \n    }\r\
    \n\r\
    \n\r\
    \n    :if ([/user find name=\$tempuser] != \"\") do={\r\
    \n        /user remove \$tempuser;\r\
    \n    }\r\
    \n    :if ([/user group find name=\$tempuser] != \"\") do={\r\
    \n        /user group remove \$tempuser;\r\
    \n    }\r\
    \n\r\
    \n    /user group add name=\$tempuser policy=ftp,read,write comment=\"temp\
    orary group for mkdir function\";\r\
    \n\r\
    \n    /user add name=\$tempuser group=\$tempuser address=127.0.0.1/32 comm\
    ent=\"temporary user for mkdir function\" password=\$passwd disabled=no;\r\
    \n\r\
    \n    :local newFTPAllowList\r\
    \n    :if (\$isFTPDisabled) do={\r\
    \n        :set newFTPAllowList 127.0.0.1\r\
    \n    } else={\r\
    \n        :if (\$oldFTPAddr = \"\") do={\r\
    \n            :set newFTPAllowList [/ip service get ftp address]\r\
    \n        } else={\r\
    \n            :set newFTPAllowList ([/ip service get ftp address],127.0.0.\
    1)\r\
    \n        }\r\
    \n    }\r\
    \n\r\
    \n    /ip service set ftp disabled=no address=\$newFTPAllowList;\r\
    \n\r\
    \n    :do {\r\
    \n        :local count 0;\r\
    \n        :while ([/file find name=\$tempfile] = \"\") do={\r\
    \n            :if (\$count >= 100) do={\r\
    \n                :set errorMsg \"Couldn't create a temp file\"\r\
    \n                :error \$errorMsg\r\
    \n            }\r\
    \n            :delay 0.05s;\r\
    \n            :set count (\$count + 1);\r\
    \n        }\r\
    \n        /file set \$tempfile contents=\"\"\r\
    \n        \r\
    \n        :do {\r\
    \n            :local ftpPort [/ip service get ftp port];\r\
    \n            :do { /ip firewall filter add action=accept chain=input comm\
    ent=\$mkdirRule dst-address=127.0.0.1 in-interface-list=!all port=\$ftpPor\
    t protocol=tcp src-address=127.0.0.1 place-before=0 } on-error={}\r\
    \n            :do { \r\
    \n                /ip firewall mangle\r\
    \n                add action=accept chain=prerouting comment=\$mkdirRule d\
    st-address=127.0.0.1 in-interface-list=!all port=\$ftpPort protocol=tcp sr\
    c-address=127.0.0.1 place-before=0\r\
    \n                add action=fasttrack-connection chain=prerouting comment\
    =\$mkdirRule dst-address=127.0.0.1 in-interface-list=!all port=\$ftpPort p\
    rotocol=tcp src-address=127.0.0.1 place-before=0\r\
    \n            } on-error={}\r\
    \n            :do { /ip firewall nat add action=accept chain=srcnat commen\
    t=\$mkdirRule dst-address=127.0.0.1 out-interface-list=!all port=\$ftpPort\
    \_protocol=tcp src-address=127.0.0.1 place-before=0 } on-error={}\r\
    \n            :do { /ip firewall raw add action=accept chain=prerouting co\
    mment=\$mkdirRule dst-address=127.0.0.1 in-interface-list=!all port=\$ftpP\
    ort protocol=tcp src-address=127.0.0.1 place-before=0 } on-error={}\r\
    \n            /tool fetch address=127.0.0.1 port=\$ftpPort mode=ftp user=\
    \$tempuser password=\$passwd src-path=\$tempfile dst-path=\"\$newFolder/\$\
    tempfile\";\r\
    \n        } on-error={\r\
    \n            :set errorMsg \"Failed to create folder \$newFolder\";\r\
    \n            :error \$errorMsg;\r\
    \n        }\r\
    \n\r\
    \n    } on-error={\r\
    \n        :log error \"mkdir: \$errorMsg\";\r\
    \n        :put \$errorMsg\r\
    \n    }\r\
    \n\r\
    \n    :do { /ip service set ftp disabled=\$isFTPDisabled address=\$oldFTPA\
    ddr; } on-error={}\r\
    \n    :do { /user remove \$tempuser; } on-error={}\r\
    \n    :do { /user group remove \$tempuser; } on-error={}\r\
    \n    :do { /file remove \$tempfile; } on-error={}\r\
    \n\r\
    \n    :local count 0;\r\
    \n    :while ([/file find name=\"\$newFolder/\$tempfile\"] = \"\") do={\r\
    \n        :if (\$count >= 20) do={\r\
    \n            :set errorMsg \"Couldn't delete \$newFolder/\$tempFile\"\r\
    \n            :log error \"mkdir: \$errorMsg\"\r\
    \n            :error \$errorMsg\r\
    \n        }\r\
    \n        :delay 0.1s;\r\
    \n        :set count (\$count + 1);\r\
    \n    }\r\
    \n\r\
    \n    :do { /file remove \"\$newFolder/\$tempfile\"; } on-error={}\r\
    \n    :do { /ip firewall filter remove [find comment=\$mkdirRule] } on-err\
    or={}\r\
    \n    :do { /ip firewall mangle remove [find comment=\$mkdirRule] } on-err\
    or={}\r\
    \n    :do { /ip firewall nat remove [find comment=\$mkdirRule] } on-error=\
    {}\r\
    \n    :do { /ip firewall raw remove [find comment=\$mkdirRule] } on-error=\
    {}\r\
    \n}\r\
    \n\r\
    \n:log info \"Created function \\\$mkdir\"\r\
    \n"

/system scheduler remove [find name=mkdir_function_on_startup];
/system scheduler add name=mkdir_function_on_startup on-event=\
    "/system script run mkdir_function;" policy=\
    ftp,reboot,read,write,policy,test,password,sniff,sensitive,romon \
    start-time=startup;

/system script run mkdir_function;
