//
//  CPlusPlus.cpp
//  MixedLanguages
//
//  Created by Borna Noureddin on 2013-10-09.
//  Copyright (c) 2013 Borna Noureddin. All rights reserved.
//  Modified by Daniel Tian (February 13, 2018)
//

#include "CPlusPlus.h"

int CPlusPlus::GetValue()
{
    return theValue;
}

void CPlusPlus::SetValue(int newVal)
{
    theValue = newVal;
}

void CPlusPlus::IncrementValue(int incr)
{
    theValue += incr;
}
