
========
TO BUILD
========

For Windows

    You will need   $(AMTL)         G:\amtl-master              .., C:\, D:\, ..
    You will need   $(SOURCEPAWN)   G:\sourcepawn-master        .., C:\, D:\, ..
    You will need   $(SOURCEMOD)    G:\sourcemod-master         .., C:\, D:\, ..
    You will need   $(MMSOURCE19)   G:\metamod-source-master    .., C:\, D:\, ..
    You will need   $(HL2SDKCSGO)   G:\hl2sdk-csgo              .., C:\, D:\, ..

        Microsoft   Visual Studio   2019 (+) C / C++ (+)        https://visualstudio.microsoft.com/
                                                                https://visualstudio.microsoft.com/downloads/
                                                                https://visualstudio.microsoft.com/thank-you-downloading-visual-studio/?sku=Community&rel=16

            Dependencies                                        https://support.microsoft.com/en-us/topic/the-latest-supported-visual-c-downloads-2647da03-1eea-4433-9aff-95f26a218cc0

                                                                https://aka.ms/vs/16/release/vc_redist.x86.exe
                                                                https://aka.ms/vs/16/release/vc_redist.x64.exe
                                                                https://aka.ms/vs/16/release/VC_redist.arm64.exe

            Settings | System | About | Advanced System Settings | Environment Variables

                For $(AMTL), $(SOURCEPAWN), $(SOURCEMOD), $(MMSOURCE19), $(HL2SDKCSGO), ..

                    Examples                                    AMTL            =   G:\amtl-master
                                                                HL2SDKCSGO      =   G:\hl2sdk-csgo

For Linux

    ../amtl-master
    ../sourcepawn-master
    ../sourcemod-master
    ../metamod-source-master
    ../hl2sdk-csgo

        In Terminal

            sudo apt-get install make
            sudo apt-get install make:amd64
            sudo apt-get install make:i386

            sudo apt-get install gcc
            sudo apt-get install gcc:amd64
            sudo apt-get install gcc:i386

            sudo apt-get install g++
            sudo apt-get install g++:amd64
            sudo apt-get install g++:i386

            sudo apt-get install gcc-multilib
            sudo apt-get install gcc-multilib:amd64
            sudo apt-get install gcc-multilib:i386

            sudo apt-get install g++-multilib
            sudo apt-get install g++-multilib:amd64
            sudo apt-get install g++-multilib:i386

            ...

                IMPORTANT       IF IT SAYS 'this action will remove N other packages from this machine', DO NOT PROCEED, EVEN IF N IS 1.
                                CANCEL THE OPERATION, AND TRY INSTALLING ANOTHER PACKAGES. FOR SURE, SOME OTHER MORE COMMANDS, ARE NEEDED AS WELL.
                                SEARCH ON GOOGLE 'how to install gcc on linux ubuntu' / 'how to install g++ on linux ubuntu', AND COPY, THEN PASTE,
                                THE 'sudo' COMMANDS, FROM THESE WEBSITES, AND EXECUTE INTO THE TERMINAL. IN THE END, YOU WILL BE ABLE TO BUILD EVERYTHING.

                    In Terminal To Build

                        TYPE IN TERMINAL 'cd ' (WITHOUT ''), THEN DRAG & DROP THE PROJECT'S FOLDER INTO THE TERMINAL. PRESS ENTER.
                        TYPE 'make' (WITHOUT ''), THEN PRESS ENTER.

Thanks

    https://github.com/alliedmodders/sourcemod                  'sourcemod-master'
    https://github.com/alliedmodders/metamod-source             'metamod-source-master'
    https://github.com/alliedmodders/amtl                       'amtl-master'
    https://github.com/alliedmodders/sourcepawn                 'sourcepawn-master'
    https://github.com/alliedmodders/hl2sdk/tree/csgo           'hl2sdk-csgo'

    https://github.com/nlohmann/json

    https://github.com/maxmind/libmaxminddb
    https://github.com/maxmind/geoip-api-c
