#!/usr/bin/python
# -*- coding: utf-8 -*-

""" WoWAcePortage2.DomUtils

    Utility Functions for Working with the XML Dom
        
"""

# ------ Basic Imports ------
import sys

# ------ Custom Imports ------



# ------ Implementation ------
def GetTextNodeText(cNode):
    if(cNode.nodeType == cNode.TEXT_NODE):
        return cNode.data
    else:
        return ''

def GetSaveValue(cDomNode, sID, cTarget, bUseMultiValue):
    cNode = cDomNode.getElementsByTagName(sID)
    if(cNode):
        cSubNode = cNode[0].childNodes
        if(bUseMultiValue):                
            for cEntry in cSubNode:
                cTarget.append(GetTextNodeText(cEntry))
            return ''
        else:
            return GetTextNodeText(cSubNode[0])
    
def GetSaveAttribute(cDomNode, sID, sAttribID):
    cNode = cDomNode.getElementsByTagName(sID)
    if(cNode):            
        if(cNode[0].attributes.has_key(sAttribID)):
            return cNode[0].attributes[sAttribID].value
        else:
            return ''