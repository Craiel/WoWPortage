#!/usr/bin/python
# -*- coding: utf-8 -*-

""" WoWAcePortage2.Addon

    This Unit Handles all Information and Work regarding a single Addon
        
"""

# ------ Basic Imports ------
import sys

# ------ Custom Imports ------


# ------ Implementation ------
class Main(object):
    
    def __init__(self):
        # Primary Parameters, neccessary for any Addon
        self.g_sTitle = ''
        self.g_sDesc  = ''
        self.g_sURL   = ''
        self.g_bValid = 0
    
        # Secondary Parameters, Optional
        self.g_sDate        = ''
        self.g_sVersion     = ''
        self.g_sInterface   = ''
        self.g_cAuthor      = []
        self.g_cCategory    = []
        self.g_cDep         = []
        self.g_cOptDep      = []