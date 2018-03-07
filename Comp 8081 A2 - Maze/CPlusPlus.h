//
//  CPlusPlus.h
//  MixedLanguages
//
//  Created by Borna Noureddin on 2013-10-09.
//  Copyright (c) 2013 Borna Noureddin. All rights reserved.
//  Modified by Daniel Tian (February 13, 2018)
//

#ifndef __MixedLanguages__CPlusPlus__
#define __MixedLanguages__CPlusPlus__

#include <iostream>

class CPlusPlus
{

public:
    CPlusPlus() { theValue = 0; };
    ~CPlusPlus() {};
    
    int GetValue();
    void SetValue(int newVal);
    void IncrementValue(int incr = 1);
    
private:
    int theValue;
    
};

#endif /* defined(__MixedLanguages__CPlusPlus__) */
