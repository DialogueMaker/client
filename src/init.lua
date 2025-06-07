--!strict

local Players = game:GetService("Players");

local packages = script.Parent.roblox_packages;
local React = require(packages.react);
local ReactRoblox = require(packages["react-roblox"]);
local DialogueMakerTypes = require(packages.DialogueMakerTypes)

type Dialogue = DialogueMakerTypes.Dialogue;
type Client = DialogueMakerTypes.Client;
type ClientSettings = DialogueMakerTypes.ClientSettings;
type Conversation = DialogueMakerTypes.Conversation;
type ConstructorClientSettings = DialogueMakerTypes.ConstructorClientSettings;
type OptionalClientConstructorProperties = DialogueMakerTypes.OptionalClientConstructorProperties;

local Client = {
  defaultSettings = {
    theme = {
      component = nil :: never;
    };
    typewriter = {
      soundTemplate = nil;
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
  conversation: Conversation;
  dialogueGUI: ScreenGui?;
  reactRoot: ReactRoblox.RootType?;
  continueDialogueBindableFunction: BindableFunction?;
}

function Client.new(properties: ConstructorProperties): Client

  local function continueDialogue(self: Client): ()

    self.continueDialogueBindableFunction:Invoke();

  end;

  local function cleanup(self: Client): ()

    self.reactRoot:unmount();
    self.dialogueGUI:Destroy();
    self.continueDialogueBindableFunction:Destroy();

  end;

  local function clone(self: Client, newProperties: OptionalClientConstructorProperties?): Client

    return Client.new(
      if newProperties then {
        settings = newProperties.settings or self.settings,
        dialogue = newProperties.dialogue or self.dialogue,
        conversation = newProperties.conversation or self.conversation,
        continueDialogueBindableFunction = newProperties.continueDialogueBindableFunction or self.continueDialogueBindableFunction,
        reactRoot = newProperties.reactRoot or self.reactRoot,
        dialogueGUI = newProperties.dialogueGUI or self.dialogueGUI,
      } else {
        settings = self.settings,
        dialogue = self.dialogue,
        conversation = self.conversation,
        continueDialogueBindableFunction = self.continueDialogueBindableFunction,
        reactRoot = self.reactRoot,
        dialogueGUI = self.dialogueGUI,
      }
    );

  end;

  local clientSettings: ClientSettings = {
    theme = {
      component = properties.settings.theme.component;
    };
    typewriter = if properties.settings.typewriter then {
      soundTemplate = properties.settings.typewriter.soundTemplate or Client.defaultSettings.typewriter.soundTemplate;
    } else Client.defaultSettings.typewriter;
    keybinds = if properties.settings.keybinds then {
      interactKey = properties.settings.keybinds.interactKey or Client.defaultSettings.keybinds.interactKey; 
      interactKeyGamepad = properties.settings.keybinds.interactKeyGamepad or Client.defaultSettings.keybinds.interactKeyGamepad; 
    } else Client.defaultSettings.keybinds;
  };

  local dialogueGUI = properties.dialogueGUI or Instance.new("ScreenGui");
  dialogueGUI.Name = "Dialogue";

  local player = Players.LocalPlayer;
  local reactRoot = properties.reactRoot or ReactRoblox.createRoot(dialogueGUI);
  dialogueGUI.Parent = player.PlayerGui;

  local client: Client = {
    settings = clientSettings;
    dialogue = properties.dialogue;
    conversation = properties.conversation;
    continueDialogueBindableFunction = properties.continueDialogueBindableFunction or Instance.new("BindableFunction");
    reactRoot = reactRoot;
    dialogueGUI = dialogueGUI;
    clone = clone;
    cleanup = cleanup;
    continueDialogue = continueDialogue;
  };

  local themeComponent = properties.dialogue.settings.theme.component or properties.conversation.settings.theme.component or client.settings.theme.component;
  local themeElement = React.createElement(themeComponent, {
    client = client;
  });
  reactRoot:render(themeElement);

  return client;

end;

return Client;