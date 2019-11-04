//
//  KeyBoadKey.h
//  RemoteControl
//
//  Created by iMac on 2019/10/28.
//  Copyright © 2019 iMac. All rights reserved.
//

#ifndef KeyBoadKey_h
#define KeyBoadKey_h

typedef enum : NSUInteger {
    NX_NOSPECIALKEY = 0xFFFF,
    NX_KEYTYPE_SOUND_UP = 0,
    NX_KEYTYPE_SOUND_DOWN = 1,
    NX_KEYTYPE_BRIGHTNESS_UP = 2,
    NX_KEYTYPE_BRIGHTNESS_DOWN = 3,
    NX_KEYTYPE_CAPS_LOCK = 4,
    NX_KEYTYPE_HELP = 5,
    NX_POWER_KEY = 6,
    NX_KEYTYPE_MUTE = 7,
    NX_UP_ARROW_KEY = 8,
    NX_DOWN_ARROW_KEY = 9,
    NX_KEYTYPE_NUM_LOCK = 10,
    
    NX_KEYTYPE_CONTRAST_UP = 11,
    NX_KEYTYPE_CONTRAST_DOWN = 12,
    NX_KEYTYPE_LAUNCH_PANEL    = 13,
    NX_KEYTYPE_EJECT = 14,
    NX_KEYTYPE_VIDMIRROR    =    15,
    
    NX_KEYTYPE_PLAY        =    16,
    NX_KEYTYPE_NEXT        =    17,
    NX_KEYTYPE_PREVIOUS    =    18,
    NX_KEYTYPE_FAST        =    19,
    NX_KEYTYPE_REWIND    =    20,
    
    NX_KEYTYPE_ILLUMINATION_UP=    21,
    NX_KEYTYPE_ILLUMINATION_DOWN    =22,
    NX_KEYTYPE_ILLUMINATION_TOGGLE=    23,
    NX_NUM_SCANNED_SPECIALKEYS    =24,
} SPECIAL_KEYType;


#endif /* KeyBoadKey_h */
