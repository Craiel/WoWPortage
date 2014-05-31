#!/usr/bin/python
# -*- coding: utf-8 -*-

""" WoWAcePortage2.AceRSS

    Loads and Imports Addons from WoWAce RSS
        
"""

# ------ Basic Imports ------
import sys, os
from xml.dom.minidom import parse

# ------ Custom Imports ------
import Settings
import Addon
from DomUtils import *
from Utils import *

"""
    <item>  
      <title>ClassTimer</title>
      <link>http://www.wowace.com/wiki/ClassTimer</link>
      <description>Timers for Buffs, DOTs, CC effects, etc..</description>
      <author>Ominous</author>
      <category>Combat</category>
      <comments>http://www.wowace.com/forums/index.php?topic=6052.0</comments>
      <enclosure url="http://www.wowace.com/files/ClassTimer/no-ext/ClassTimer-r40049.zip" length="24286" type="application/zip" />
      <guid>http://www.wowace.com/files/ClassTimer/no-ext/ClassTimer-r40049.zip</guid>
      <pubDate>Fri, 15 Jun 2007 12:40:38 +0000</pubDate>
      <wowaddon:interface>20100</wowaddon:interface>
      <wowaddon:version>40049</wowaddon:version>
      <wowaddon:dependencies>Ace2</wowaddon:dependencies>
      <wowaddon:dependencies>DewdropLib</wowaddon:dependencies>
      <wowaddon:dependencies>Babble-2.2</wowaddon:dependencies>
      <wowaddon:dependencies>SharedMediaLib</wowaddon:dependencies>
      <wowaddon:optionaldeps>Expo</wowaddon:optionaldeps>
    </item>
"""

# ------ Implementation ------
def UpdateAceFromRSS(self, cAddonHandler, cSettings):
    sAceURI     = cSettings.GetSetting('AceURI')
    sLocalFile  = GetScriptHomeDir()+'AceRSS.xml'
    DownloadFile(sAceURI, sLocalFile)
    if(os.path.exists(sLocalFile)):
        cDom = parse(sLocalFile)
        cItems = cDom.getElementsByTagName('item')
        for cItem in cItems:
            cAddon = Addon.Main()
            cAddon.g_sTitle       = GetSaveValue(cDomNode, 'title'               , '', False)
            cAddon.g_sDesc        = GetSaveValue(cDomNode, 'description'         , '', False)
            cAddon.g_sDate        = GetSaveValue(cDomNode, 'pubDate'             , '', False)
            cAddon.g_sVersion     = GetSaveValue(cDomNode, 'wowaddon:version'    , '', False)
            cAddon.g_sInterface   = GetSaveValue(cDomNode, 'wowaddon:interface'  , '', False)
        
            cAddon.g_sURL         = GetSaveAttribute(cDomNode, 'enclosure', 'url')
        
            GetSaveValue(cDomNode, 'author', cAddon.g_cAuthor, True)
            GetSaveValue(cDomNode, 'category', cAddon.g_cCategory, True)
            GetSaveValue(cDomNode, 'wowaddon:dependencies', cAddon.g_cDep, True)
            GetSaveValue(cDomNode, 'wowaddon:optionaldeps', cAddon.g_cOptDep, True)