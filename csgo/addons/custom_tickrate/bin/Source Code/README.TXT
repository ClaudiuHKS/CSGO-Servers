
========
TO BUILD
========

For Windows

    You will need   $(AMTL)         G:\amtl-master              .., C:\, D:\, ..
    You will need   $(SOURCEPAWN)   G:\sourcepawn-master        .., C:\, D:\, ..
    You will need   $(SPAWN)        G:\sourcepawn-master        .., C:\, D:\, ..
    You will need   $(SP)           G:\sourcepawn-master        .., C:\, D:\, ..
    You will need   $(SOURCEMOD)    G:\sourcemod-master         .., C:\, D:\, ..
    You will need   $(SM)           G:\sourcemod-master         .., C:\, D:\, ..
    You will need   $(SMOD)         G:\sourcemod-master         .., C:\, D:\, ..
    You will need   $(MMSOURCE19)   G:\metamod-source-master    .., C:\, D:\, ..
    You will need   $(MMS)          G:\metamod-source-master    .., C:\, D:\, ..
    You will need   $(MMSOURCE)     G:\metamod-source-master    .., C:\, D:\, ..
    You will need   $(MMS19)        G:\metamod-source-master    .., C:\, D:\, ..
    You will need   $(HL2SDKCSGO)   G:\hl2sdk-csgo              .., C:\, D:\, ..
    You will need   $(CSGO)         G:\hl2sdk-csgo              .., C:\, D:\, ..
    You will need   $(HL2SDKCSS)    G:\hl2sdk-css               .., C:\, D:\, ..
    You will need   $(CSS)          G:\hl2sdk-css               .., C:\, D:\, ..
    You will need   $(HL2SDKDOD)    G:\hl2sdk-dods              .., C:\, D:\, ..
    You will need   $(HL2SDKDODS)   G:\hl2sdk-dods              .., C:\, D:\, ..
    You will need   $(DOD)          G:\hl2sdk-dods              .., C:\, D:\, ..
    You will need   $(DODS)         G:\hl2sdk-dods              .., C:\, D:\, ..
    You will need   $(JSON)         G:\json-develop             .., C:\, D:\, ..
    You will need   $(NLOHMANN)     G:\json-develop             .., C:\, D:\, ..
    You will need   $(HLSDK)        G:\hlsdk-master             .., C:\, D:\, ..
    You will need   $(HL)           G:\hlsdk-master             .., C:\, D:\, ..
    You will need   $(METAMOD)      G:\metamod-hl1-master       .., C:\, D:\, ..
    You will need   $(MM)           G:\metamod-hl1-master       .., C:\, D:\, ..
    You will need   $(AMXMODX)      G:\amxmodx-master           .., C:\, D:\, ..
    You will need   $(AMXX)         G:\amxmodx-master           .., C:\, D:\, ..
    You will need   $(AMX)          G:\amxmodx-master           .., C:\, D:\, ..
    You will need   $(DET)          G:\Detours-master           .., C:\, D:\, ..
    You will need   $(DETS)         G:\Detours-master           .., C:\, D:\, ..
    You will need   $(DETOUR)       G:\Detours-master           .., C:\, D:\, ..
    You will need   $(DETOURS)      G:\Detours-master           .., C:\, D:\, ..

        Microsoft   Visual Studio   2022 (+)    C / C++         https://visualstudio.microsoft.com/
                                                                https://visualstudio.microsoft.com/downloads/

            Dependencies                                        https://learn.microsoft.com/en-us/cpp/windows/latest-supported-vc-redist

                                                                https://aka.ms/vs/17/release/vc_redist.x86.exe
                                                                https://aka.ms/vs/17/release/vc_redist.x64.exe
                                                                https://aka.ms/vs/17/release/vc_redist.arm64.exe

            Settings → System → About → Advanced System Settings → Environment Variables → System Variables → New

                For $(AMTL), $(SOURCEPAWN), $(SPAWN), $(SOURCEMOD), $(SM), $(MMSOURCE19), $(MMS), ..

                    Examples                                    AMTL            →   G:\amtl-master
                                                                CSGO            →   G:\hl2sdk-csgo

For Linux

    These Folders In 'Documents'

    ../amtl-master
    ../sourcepawn-master
    ../sourcemod-master
    ../metamod-source-master
    ../hl2sdk-csgo
    ../hl2sdk-css
    ../hl2sdk-dods
    ../json-develop
    ../hlsdk-master
    ../metamod-hl1-master
    ../amxmodx-master
    ../Detours-master

        In Terminal

            su root                             (Then Type Your ROOT Password If Asked)

            sudo apt-get install make           (Then Type Y If Asked)
            sudo apt-get install g++            (Then Type Y If Asked)
            sudo apt-get install g++-multilib   (Then Type Y If Asked)

                In Terminal To Build            (Your Project Folder Must Be In 'Documents')

                    TYPE IN TERMINAL 'cd ' (WITHOUT ''), THEN DRAG & DROP THE PROJECT'S FOLDER INTO THE TERMINAL. PRESS ENTER.
                    TYPE 'make' (WITHOUT ''), THEN PRESS ENTER.

Thanks

    https://github.com/alliedmodders/sourcemod                  'sourcemod-master'
    https://github.com/alliedmodders/amxmodx                    'amxmodx-master'
    https://github.com/alliedmodders/hlsdk                      'hlsdk-master'
    https://github.com/alliedmodders/metamod-hl1                'metamod-hl1-master'
    https://github.com/alliedmodders/metamod-source             'metamod-source-master'
    https://github.com/alliedmodders/amtl                       'amtl-master'
    https://github.com/alliedmodders/sourcepawn                 'sourcepawn-master'
    https://github.com/alliedmodders/hl2sdk/tree/csgo           'hl2sdk-csgo'
    https://github.com/alliedmodders/hl2sdk/tree/css            'hl2sdk-css'
    https://github.com/alliedmodders/hl2sdk/tree/dods           'hl2sdk-dods'
    https://github.com/nlohmann/json                            'json-develop'
    https://github.com/microsoft/Detours                        'Detours-master'
    https://github.com/maxmind/libmaxminddb
    https://github.com/maxmind/geoip-api-c
