#!/usr/bin/python
# -*- coding: utf-8 -*-

""" WoWAcePortage2.Utils

    general Utility Functions
        
"""

# ------ Basic Imports ------
import sys, os
import urllib2

# ------ Custom Imports ------


# ------ Implementation ------
def GetScriptHomeDir():
    return os.path.dirname(sys.argv[0])

def DownloadFile(sFile, sTarget):
    iBlockSize = 2048
    fTarget = open(sTarget, 'wb')
    fSource = urllib2.urlopen(sFile)
    sData = 'empty'
    while(len(sData) > 0):
        sData = fSource.read(iBlockSize)
        fTarget.write(sData)    
    fTarget.close()
    fSource.close()