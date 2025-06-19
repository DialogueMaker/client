--!strict

local Players = game:GetService("Players");

local packages = script.Parent.roblox_packages;
local React = require(packages.react);
local ReactRoblox = require(packages["react-roblox"]);
local DialogueMakerTypes = require(packages.DialogueMakerTypes)

type Dialogue = DialogueMakerTypes.Dialogue;
type DialogueGui = DialogueMakerTypes.DialogueGui;
type Client = DialogueMakerTypes.Client;
type ClientSettings = DialogueMakerTypes.ClientSettings;
type ConstructorClientSettings = DialogueMakerTypes.ConstructorClientSettings;
type OptionalClientConstructorProperties = DialogueMakerTypes.OptionalClientConstructorProperties;

local Client = {
  defaultSettings = {
    theme = {
      component = nil :: never;
    };
    typewriter = {
      canPlayerSkipDelay = true;
      shouldShowResponseWhileTyping = true;
      characterDelaySeconds = 0.025;
    };
    keybinds = {
      interactKey = nil;
      interactKeyGamepad = nil;
    };
  } :: ClientSettings;
};

export type ConstructorProperties = {
  settings: ConstructorClientSettings;
  dialogue: Dialogue;
  dialogueGUI: DialogueGui?;
  reactRoot: ReactRoblox.RootType?;
  continueDialogueBindableFunction: BindableFunction?;
}

--[[
  Creates a new Client object and associated GUI elements if necessary.
]]
function Client.new(properties: ConstructorProperties): Client

  local conversation = properties.dialogue:getConversation();

  local function continueDialogue(self: Client): ()

    self.continueDialogueBindableFunction:Invoke();

  end;

  local function cleanup(self: Client): ()

    self.reactRoot:unmount();
    self.dialogueGUI:Destroy();
    self.continueDialogueBindableFunction:Destroy();

  end;

  local function clone(self: Client, newProperties: OptionalClientConstructorProperties?): Client

    local clonedProperties = if newProperties then {
      settings = newProperties.settings or self.settings,
      dialogue = newProperties.dialogue or self.dialogue,
      continueDialogueBindableFunction = newProperties.continueDialogueBindableFunction or self.continueDialogueBindableFunction,
      reactRoot = newProperties.reactRoot or self.reactRoot,
      dialogueGUI = newProperties.dialogueGUI or self.dialogueGUI,
    } else properties;

    return Client.new(clonedProperties);

  end;

  local clientSettings: ClientSettings = {
    theme = {
      component = properties.settings.theme.component;
    };
    typewriter = if properties.settings.typewriter then {
      canPlayerSkipDelay = properties.settings.typewriter.canPlayerSkipDelay ~= nil and properties.settings.typewriter.canPlayerSkipDelay or Client.defaultSettings.typewriter.canPlayerSkipDelay;
      shouldShowResponseWhileTyping = properties.settings.typewriter.shouldShowResponseWhileTyping ~= nil and properties.settings.typewriter.shouldShowResponseWhileTyping or Client.defaultSettings.typewriter.shouldShowResponseWhileTyping;
      characterDelaySeconds = properties.settings.typewriter.characterDelaySeconds ~= nil and properties.settings.typewriter.characterDelaySeconds or Client.defaultSettings.typewriter.characterDelaySeconds;
    } else Client.defaultSettings.typewriter;
    keybinds = if properties.settings.keybinds then {
      interactKey = properties.settings.keybinds.interactKey or Client.defaultSettings.keybinds.interactKey; 
      interactKeyGamepad = properties.settings.keybinds.interactKeyGamepad or Client.defaultSettings.keybinds.interactKeyGamepad; 
    } else Client.defaultSettings.keybinds;
  };

  local dialogueGUI = properties.dialogueGUI; 
  if not dialogueGUI then

    local player = Players.LocalPlayer;
    local newDialogueGui = Instance.new("ScreenGui");
    newDialogueGui.Name = "Dialogue";
    newDialogueGui.Parent = player.PlayerGui;
    dialogueGUI = newDialogueGui;
    
  end;
  
  assert(dialogueGUI, "Dialogue GUI must be provided or created.");
    
  if dialogueGUI:IsA("BillboardGui") then

    if not dialogueGUI.Adornee then

      warn("BillboardGui should have an adornee set. Input events may not work correctly without it.");
    
    end;

    if not dialogueGUI:IsDescendantOf(Players.LocalPlayer.PlayerGui) then

      warn("BillboardGui should be a descendant of PlayerGui for proper input handling.");
    
    end;

  end;

  local reactRoot = properties.reactRoot or ReactRoblox.createRoot(dialogueGUI);

  local client: Client = {
    settings = clientSettings;
    conversation = conversation;
    dialogue = properties.dialogue;
    continueDialogueBindableFunction = properties.continueDialogueBindableFunction or Instance.new("BindableFunction");
    reactRoot = reactRoot;
    dialogueGUI = dialogueGUI;
    clone = clone;
    cleanup = cleanup;
    continueDialogue = continueDialogue;
  };

  local themeComponent = properties.dialogue.settings.theme.component or conversation.settings.theme.component or client.settings.theme.component;
  local themeElement = React.createElement(themeComponent, {
    client = client;
  });
  reactRoot:render(themeElement);

  return client;

end;

return Client;