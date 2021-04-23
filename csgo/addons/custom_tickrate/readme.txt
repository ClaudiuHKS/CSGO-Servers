
Windows Process Priority Class

    From Low Priority [Worse] To High Priority [Better]

        IDLE_PRIORITY_CLASS             =       64          =       0x40
        BELOW_NORMAL_PRIORITY_CLASS     =       16384       =       0x4000
        NORMAL_PRIORITY_CLASS           =       32          =       0x20
        ABOVE_NORMAL_PRIORITY_CLASS     =       32768       =       0x8000
        HIGH_PRIORITY_CLASS             =       128         =       0x80
        REALTIME_PRIORITY_CLASS         =       256         =       0x100

Linux Process Priority Class

    From Low Priority [Worse] To High Priority [Better]

        IDLE_PRIORITY_CLASS             =   19      18      17      16      15      14      13      12
        BELOW_NORMAL_PRIORITY_CLASS     =   11      10      9       8       7       6       5       4
        NORMAL_PRIORITY_CLASS           =   3       2       1       0       -1      -2      -3      -4
        ABOVE_NORMAL_PRIORITY_CLASS     =   -5      -6      -7      -8      -9
        HIGH_PRIORITY_CLASS             =   -10     -11     -12     -13     -14     -15     -16     -17
        REALTIME_PRIORITY_CLASS         =   -18     -19     -20

Valid Tick Rates

    0.0078125   Interval Per Tick   =   128     Tick Rate
    0.008       Interval Per Tick   =   125     Tick Rate
    0.01        Interval Per Tick   =   100     Tick Rate
    0.0125      Interval Per Tick   =   80      Tick Rate
    0.015625    Interval Per Tick   =   64      Tick Rate
    0.02        Interval Per Tick   =   50      Tick Rate
    0.025       Interval Per Tick   =   40      Tick Rate
    0.03125     Interval Per Tick   =   32      Tick Rate
    0.04        Interval Per Tick   =   25      Tick Rate
