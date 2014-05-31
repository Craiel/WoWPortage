#!/usr/bin/env python

#--------------------------------------------
# Includes
import Tkinter

#--------------------------------------------
# Constants

C_RAIDMEMBERS   = 25
C_VERSION       = '0.1'

#--------------------------------------------
# Globals

g_cUsers = []

#--------------------------------------------
class User(object):
    g_iRndRate = 0
    g_iItems   = 0
    g_sName    = ''
    
    def AddItem(self):
        self.g_iItems   = self.g_iItems + 1
        self.g_iRndRate = self.g_iRndRate - (C_RAIDMEMBERS - 1)
    
    def __init__(self, Name):
        self.g_iItems   = 0
        self.g_iRndRate = 100
        self.g_sName    = Name
#--------------------------------------------
class UI(object):
    g_cTKRoot  = Tkinter.Tk()
    
    def __init__(self):
        self.g_cTKRoot.title(' Relational Random Simulation %s' % C_VERSION)
        self.g_cTKRoot.withdraw()
        
        self._widgets = {}
        
        cListBox = Tkinter.Listbox(self.g_cTKRoot, width = 50, height = 25)
        cListBox.pack()
        cListBox.bind('<Button-1>', self.onSelect)
        self._widgets['ListBox'] = cListBox
        
        cEntry = Tkinter.Label(self.g_cTKRoot)
        cEntry.pack()
        self._widgets['lItems'] = cEntry
        
        cEntry = Tkinter.Label(self.g_cTKRoot)
        cEntry.pack()
        self._widgets['lRndRate'] = cEntry
        
    def onSelect(self, Param):
        try:
            cSel = self._widgets['ListBox'].selection_get()
        except:
            return
        
    def Update(self, Entrys):
        for cEntry in Entrys:
            self._widgets['ListBox'].insert(9999, cEntry.g_sName)
        
    def Show(self):
        self.g_cTKRoot.deiconify()
        self.g_cTKRoot.mainloop()
#--------------------------------------------
for i in range(1, 26):
    g_cUsers.append(User(i))

g_cUI = UI()
g_cUI.Update(g_cUsers)
g_cUI.Show()