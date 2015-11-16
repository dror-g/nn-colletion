#!/usr/bin/python

# Howto, Code license, Credits, etc: http://sourceforge.net/projects/triathlon/


import wx
import os
import sys
import WXElements
import InputManager

class FileType():
    def __init__(self,iconRegularFilename="",iconGreyedFilename="",typeExtension=""):
        self.iconRegularFilename = iconRegularFilename
        self.iconGreyedFilename = iconGreyedFilename
        self.typeExtension = typeExtension
        self.files=[]
        self.updateFileList()
    def updateFileList(self):
        path = os.getcwd()
        fileList = os.listdir(path)
        self.files=[]
        for fileName in fileList:
            if fileName[-len(self.typeExtension):] == self.typeExtension:
                self.files.append(fileName[:-(1+len(self.typeExtension))])
        

filetypes = {}

filetypes["Profile"] = FileType(iconRegularFilename=("icons"+os.sep+"profile.png"),
                                iconGreyedFilename=("icons"+os.sep+"profilegreyed.png"),
                                typeExtension="profile")

filetypes["Train data"] = FileType(iconRegularFilename=("icons"+os.sep+"traindata.png"),
                                   iconGreyedFilename=("icons"+os.sep+"traindatagreyed.png"),
                                   typeExtension="train")

filetypes["Test data"] = FileType(iconRegularFilename=("icons"+os.sep+"testdata.png"),
                         iconGreyedFilename=("icons"+os.sep+"testdatagreyed.png"),
                         typeExtension="test")

filetypes["Artificial neural network"] = FileType(iconRegularFilename=("icons"+os.sep+"net.png"),
                                                  iconGreyedFilename=("icons"+os.sep+"netgreyed.png"),
                                                  typeExtension="net")

filetypes["Support vector machine"] = FileType(iconRegularFilename=("icons"+os.sep+"svm.png"),
                                                  iconGreyedFilename=("icons"+os.sep+"svmgreyed.png"),
                                                  typeExtension="svm")

filetypes["Direct Feedback Profile"] = FileType(iconRegularFilename=("icons"+os.sep+"feedback.png"),
                                                typeExtension="feedback")

class IconApp():
    def __init__(self,
                 iconRegularFilename = "" , 
                 iconGreyedFilename="", 
                 level=0, 
                 dependencies=[],
                 result=[],
                 moduleName="",
                 description=""):
        self.iconRegularFilename = iconRegularFilename
        self.iconGreyedFilename = iconGreyedFilename
        self.level = level
        self.dependencies = dependencies
        self.result= result
        self.moduleName= moduleName
        self.description= description              


apps = {}

#apps["Data visualizer"] = IconApp(iconRegularFilename=("icons"+os.sep+"visualizer.png"),
#                                  moduleName="TriathlonAnalyzer",
#                                  description="Research and Debug tool for data visualization")

apps["Auditor (active)"] = IconApp(iconRegularFilename=("icons"+os.sep+"actauditor.png"),
                                   result=["Profile","Train data","Test data"],
                                   moduleName="TriathlonAuditor",
                                   description="Profile creation and data collection tool for auditing an active gamer")

#apps["Auditor (passive)"] = IconApp(iconRegularFilename=("icons"+os.sep+"pasauditor.png"),
#                                   result=["Profile","Train data","Test data"],
#                                   moduleName="TriathlonPassiveAuditor",
#                                   description="Profile creation and data collection tool for auditing a passive gamer")

apps["Direct Feedback"] = IconApp(iconRegularFilename=("icons"+os.sep+"directfeedback.png"),
                                   result=["Direct Feedback Profile"],
                                   moduleName="TriathlonDirectFeedbackPlayer",
                                   description="Configure and play a direct feedback setup")

apps["ANN Breeder"] = IconApp(iconRegularFilename=("icons"+os.sep+"breeder.png"),
                                                  iconGreyedFilename=("icons"+os.sep+"breedergreyed.png"),
                                                  level=1,
                                                  dependencies=["Train data","Test data"],
                                                  result=["Artificial neural network"],
                                                  moduleName="TriathlonBreeder",
                                                  description="Generate and train an artificial neural network from datasets")

#apps["SVM Breeder"] = IconApp(iconRegularFilename=("icons"+os.sep+"svmbreeder.png"),
#                                                  iconGreyedFilename=("icons"+os.sep+"svmbreedergreyed.png"),
#                                                  level=1,
#                                                  dependencies=["Train data","Test data"],
#                                                  result=["Support vector machine"],
#                                                  moduleName="TriathlonSVMBreeder",
#                                                  description="Generate and train a support vector machine classifier from datasets")

apps["ANN Player"] = IconApp(iconRegularFilename=("icons"+os.sep+"player.png"),
                         iconGreyedFilename=("icons"+os.sep+"playergreyed.png"),
                         level=2,
                         dependencies=["Profile","Artificial neural network"],
                         moduleName="TriathlonPlayer",
                         description="Configure and play an artificial neural network setup")

#apps["ANN Analyzer"] = IconApp(iconRegularFilename=("icons"+os.sep+"analyzer.png"),
#                         iconGreyedFilename=("icons"+os.sep+"analyzergreyed.png"),
#                         level=2,
#                         dependencies=["Train data","Test data","Artificial neural network"],
#                         moduleName="TriathlonANNAnalyzer",
#                         description="Analyze an artificial neural network")

#apps["SVM Player"] = IconApp(iconRegularFilename=("icons"+os.sep+"svmplayer.png"),
#                         iconGreyedFilename=("icons"+os.sep+"svmplayergreyed.png"),
#                         level=2,
#                         dependencies=["Profile","Support vector machine"],
#                         moduleName="TriathlonSVMPlayer",
#                         description="Configure and play a support vector machine classifier setup")

#apps["SVM Analyzer"] = IconApp(iconRegularFilename=("icons"+os.sep+"svmanalyzer.png"),
#                         iconGreyedFilename=("icons"+os.sep+"svmanalyzergreyed.png"),
#                         level=2,
#                         dependencies=["Train data","Test data","Support vector machine"],
#                         moduleName="TriathlonSVMAnalyzer",
#                         description="Analyze a support vector machine classifier")


app_Max_Level = max([apps[each].level for each in apps.keys()])


class ReqPanel(wx.Panel):
    def __init__(self, parent,app):
        wx.Panel.__init__(self, parent)
        self.app = app
        sizer = wx.FlexGridSizer(0,1,0,0)
        self.icons = []
        for req in apps[app].dependencies:
            self.icons.append(wx.StaticBitmap(self, -1, wx.Image(filetypes[req].iconRegularFilename , wx.BITMAP_TYPE_ANY).ConvertToBitmap()))
            sizer.Add(self.icons[-1], 1, wx.ALIGN_CENTER)
            self.icons[-1].SetToolTip(wx.ToolTip("Required: "+req))
        self.updateIcons()
        self.SetSizer(sizer)
    def updateIcons(self):
        for reqI in range(len(apps[self.app].dependencies)):
            if not(currentName in filetypes[apps[self.app].dependencies[reqI]].files):
                self.icons[reqI].SetBitmap(wx.Image(filetypes[(apps[self.app].dependencies)[reqI]].iconGreyedFilename , wx.BITMAP_TYPE_ANY).ConvertToBitmap())
            else:
                self.icons[reqI].SetBitmap(wx.Image(filetypes[(apps[self.app].dependencies)[reqI]].iconRegularFilename , wx.BITMAP_TYPE_ANY).ConvertToBitmap())         


class ResPanel(wx.Panel):
    def __init__(self, parent,app):
        wx.Panel.__init__(self, parent)
        self.app = app
        sizer = wx.FlexGridSizer(0,1,0,0)
        self.icons = []
        for res in (apps[app].result):
            self.icons.append(wx.StaticBitmap(self, -1, wx.Image(filetypes[res].iconRegularFilename , wx.BITMAP_TYPE_ANY).ConvertToBitmap()))
            sizer.Add(self.icons[-1], 1, wx.ALIGN_CENTER)
            self.icons[-1].SetToolTip(wx.ToolTip("Result: "+res))
        self.updateIcons()
        self.SetSizer(sizer)
    def updateIcons(self):
        allReqsMet = True
        for req in apps[self.app].dependencies:
            if not(currentName in filetypes[req].files):
                allReqsMet = False
        for resI in range(len(apps[self.app].result)):
            if not(allReqsMet):
                self.icons[resI].SetBitmap(wx.Image(filetypes[(apps[self.app].result)[resI]].iconGreyedFilename , wx.BITMAP_TYPE_ANY).ConvertToBitmap())
            else:
                self.icons[resI].SetBitmap(wx.Image(filetypes[(apps[self.app].result)[resI]].iconRegularFilename , wx.BITMAP_TYPE_ANY).ConvertToBitmap())         


class IconAppPanel(wx.Panel):
    def __init__(self, parent,app):
        wx.Panel.__init__(self, parent, style=wx.RAISED_BORDER)
        sizer = wx.FlexGridSizer(1,3,0,0)
        self.app = app
        sizer.AddGrowableRow(0)
	self.reqPanel = ReqPanel(self,app)
        self.cenPanel = wx.Panel(self)
        self.resPanel = ResPanel(self,app)
        cenSizer = wx.FlexGridSizer(2,1,0,0)
        self.startButton = wx.BitmapButton(self.cenPanel, id=-1, bitmap=wx.Image(apps[app].iconRegularFilename , wx.BITMAP_TYPE_ANY).ConvertToBitmap())
        self.startButton.Bind(wx.EVT_BUTTON, self.startAppl)
        self.startButton.SetToolTip(wx.ToolTip(apps[app].description))
        font = wx.Font(10, wx.FONTFAMILY_DEFAULT, wx.FONTSTYLE_NORMAL, wx.FONTWEIGHT_BOLD)       
        self.title = wx.StaticText(self.cenPanel,label=app)
        self.title.SetFont(font)
        cenSizer.Add(self.title, 1, wx.ALIGN_CENTER)
        cenSizer.Add(self.startButton, 1, wx.ALIGN_CENTER)
        sizer.Add(self.reqPanel, 1, wx.ALIGN_CENTER)
        sizer.Add(self.cenPanel, 1, wx.ALIGN_CENTER)
        sizer.Add(self.resPanel, 1, wx.ALIGN_CENTER)
        self.cenPanel.SetSizer(cenSizer)
        self.updateAppPanel()
        self.SetSizer(sizer)
    def startAppl(self, event):
        allReqsMet = True
        for req in apps[self.app].dependencies:
            if not(currentName in filetypes[req].files):
                allReqsMet = False
        if allReqsMet:
            global currentApp
            global restart
            restart = True
            currentApp = self.app
            self.GetGrandParent().GetGrandParent().Close()
    def updateAppPanel(self):
        allReqsMet = True
        for req in apps[self.app].dependencies:
            if not(currentName in filetypes[req].files):
                allReqsMet = False
        if allReqsMet:
            self.startButton.SetBitmapLabel( wx.Image(apps[self.app].iconRegularFilename , wx.BITMAP_TYPE_ANY).ConvertToBitmap())
        else:
            self.startButton.SetBitmapLabel( wx.Image(apps[self.app].iconGreyedFilename , wx.BITMAP_TYPE_ANY).ConvertToBitmap())
        self.reqPanel.updateIcons()
        self.resPanel.updateIcons()
        

class LevelPanel(wx.Panel):
    def __init__(self, parent,level):        
        wx.Panel.__init__(self, parent)
        self.level = level
        sizer = wx.FlexGridSizer(0,1,0,0)
        self.apps=[]
        self.appcounter = 0
        sizer.AddGrowableCol(0)
        for eachApp in sorted(apps.keys()):
            if apps[eachApp].level==level:
                self.apps.append(IconAppPanel(self, eachApp) )
                sizer.AddGrowableRow(self.appcounter)
                sizer.Add(self.apps[self.appcounter], 1, wx.ALIGN_CENTER)
                self.appcounter+=1
        self.SetSizer(sizer)


class StarterMain(wx.Frame):
    def __init__(self):
        wx.Frame.__init__(self,None,title="Triathlon",size=(720,512))
        self.panel = wx.Panel(self, wx.ID_ANY)
        MenuBar = wx.MenuBar()
        self.FileMenu = wx.Menu()
        item = self.FileMenu.Append(wx.ID_EXIT, text="Quit")
        self.Bind(wx.EVT_MENU, self.OnQuit, item)
        MenuBar.Append(self.FileMenu, "Menu")
        self.SetMenuBar(MenuBar)
        sizer = wx.FlexGridSizer(0,1,0,0)
        sizer.AddGrowableCol(0)
        self.nameChoice = wx.Choice(self.panel, choices=[])
        self.nameChoice.Bind(wx.EVT_CHOICE, self.UpdateIcons)
        self.nameChoice.SetToolTip(wx.ToolTip("Profile name"))
        sizer.Add(wx.StaticText(self.panel,label=""), 1, wx.ALIGN_CENTER)
        sizer.Add(self.nameChoice, 1, wx.ALIGN_CENTER)
        sizer.Add(wx.StaticText(self.panel,label=""), 1, wx.ALIGN_CENTER)
        self.allLevelspanel = wx.Panel(self.panel, wx.ID_ANY)
        allLevelssizer = wx.FlexGridSizer(1,app_Max_Level+1,0,0)
        allLevelssizer.AddGrowableRow(0)
        self.levelpanels = []
        for level in range(app_Max_Level+1):
            self.levelpanels.append(LevelPanel(self.allLevelspanel, level))
            allLevelssizer.AddGrowableCol(level) 
            allLevelssizer.Add(self.levelpanels[level], 1, wx.EXPAND)
        self.allLevelspanel.SetSizer(allLevelssizer)
        sizer.AddGrowableRow(3)
        sizer.Add(self.allLevelspanel, 1, wx.EXPAND)
        self.updateAvailableNames()
        self.panel.SetSizer(sizer)
        self.panel.Layout()
    def OnQuit(self, event=None):
        self.Close()
    def updateAvailableNames(self):
        namelist={}
        for filetype in filetypes:
            for name in filetypes[filetype].files:
                namelist[name]=""
        self.nameChoice.SetItems(sorted(namelist.keys())+["New Profile"])
        self.nameChoice.SetSelection(0)
        self.UpdIcons()
    def UpdateIcons(self, event):
        self.UpdIcons()
    def UpdIcons(self):
        global currentName
        currentName = self.nameChoice.GetStringSelection()
        for ftype in filetypes:
            filetypes[ftype].updateFileList()
        if (currentName=="New Profile"):
            currentName=""
        for levelPanel in self.levelpanels:
            for appPanel in levelPanel.apps:
                appPanel.updateAppPanel()
    

class StarterApp(wx.App):
    def __init__(self, redirect = False):
        wx.App.__init__(self)
        ib = wx.IconBundle()
        bmp = wx.Image('icons'+os.sep+'triathlon.png' , wx.BITMAP_TYPE_ANY).ConvertToBitmap()
        icon = wx.EmptyIcon()
        icon.CopyFromBitmap(bmp)
        ib.AddIcon(icon)
        self.mainWindow = StarterMain()
        self.mainWindow.SetIcons(ib)
        self.mainWindow.Center()
        self.mainWindow.Show(True)


def run():
        global currentName
        global currentApp
        global restart
        restart = False
        currentName = ""
        currentApp = ""
        starterApp = StarterApp()
        starterApp.mainWindow.updateAvailableNames()
        starterApp.MainLoop()
        if (currentApp != ""):
            restart = True
            os.system('python '+apps[currentApp].moduleName+'.py '+currentName)
            

if __name__ == "__main__":
        global restart
        restart = True       
        while (True):
            if restart:
                run()
            else:
                break
        
