--!strict

local Players = game:GetService("Players");

local packages = script.Parent.roblox_packages;
local Conversation = require(packages.conversation);
local React = require(packages.react);
local ReactRoblox = require(packages["react-roblox"]);
local DialogueMakerTypes = require(packages.dialogue_maker_types)

type Dialogue = DialogueMakerTypes.Dialogue;
type Client = DialogueMakerTypes.Client;
type ClientSettings = DialogueMakerTypes.ClientSettings;
type Conversation = DialogueMakerTypes.Conversation;
type ConstructorClientSettings = DialogueMakerTypes.ConstructorClientSettings;

local Client = {
  sharedClient = nil :: Client?;
  defaultSettings = {
    keybinds = {
      interactKey = nil;
      interactKeyGamepad = nil;
    };
  } :: ClientSettings;
};

function Client:waitForSharedClient(): Client

  repeat task.wait() until Client.sharedClient;

  return self:getSharedClient();

end;

function Client:getSharedClient(): Client

  assert(Client.sharedClient, "[Dialogue Maker] Shared dialogue client not set.");

  return Client.sharedClient;

end;

function Client:setSharedClient(client: Client?): ()

  assert(not Client.sharedClient, "[Dialogue Maker] Shared dialogue client already set.");
  Client.sharedClient = client;

end;

function Client.new(clientSettingOverrides: ConstructorClientSettings): Client

  local player = Players.LocalPlayer;
  local clientSettings: ClientSettings = {
    theme = clientSettingOverrides.theme;
    keybinds = {
      interactKey = if clientSettingOverrides and clientSettingOverrides.keybinds then clientSettingOverrides.keybinds.interactKey else Client.defaultSettings.keybinds.interactKey; 
      interactKeyGamepad = if clientSettingOverrides and clientSettingOverrides.keybinds then clientSettingOverrides.keybinds.interactKeyGamepad else Client.defaultSettings.keybinds.interactKeyGamepad; 
    };
  };

  local settingsChangedEvent = Instance.new("BindableEvent");
  local dialogueChangedEvent = Instance.new("BindableEvent");
  local continueDialogueFunction = Instance.new("BindableFunction");

  local reactRoot: ReactRoblox.RootType? = nil;
  local dialogueGUI: ScreenGui? = nil;
  local dialogue: Dialogue? = nil;

  local function continueDialogue(self: Client): ()

    continueDialogueFunction:Invoke();

  end;

  local function cleanup(self: Client): ()

    if reactRoot then

      reactRoot:unmount();
      reactRoot = nil;

    end;

    if dialogueGUI then

      dialogueGUI:Destroy();
      dialogueGUI = nil;

    end;

  end;

  local function getDialogue(self: Client): Dialogue?

    return dialogue;

  end;

  local function setDialogue(self: Client, newDialogue: Dialogue?): ()

    if dialogue == newDialogue or (dialogue and newDialogue and dialogue.moduleScript == newDialogue.moduleScript) then

      return;

    end;

    while newDialogue and newDialogue.type == "Redirect" do

      newDialogue:runInitializationAction(self);
      newDialogue = newDialogue:findNextVerifiedDialogue();

    end;

    dialogue = newDialogue;
    dialogueChangedEvent:Fire();

    if dialogue then

      self:renderDialogue();

    else

      self:cleanup();

    end;

  end;

  local function setContinueDialogueFunction(self: Client, newFunction: (() -> ())?): ()

    continueDialogueFunction.OnInvoke = newFunction or function() end;

  end;

  local function renderDialogue(self: Client): ()

    assert(dialogue, "[Dialogue Maker] Cannot render dialogue without a dialogue set.");

    local newDialogueGUI = dialogueGUI or Instance.new("ScreenGui");
    newDialogueGUI.Name = "Dialogue";
    dialogueGUI = newDialogueGUI;

    local newReactRoot = reactRoot or ReactRoblox.createRoot(newDialogueGUI);
    reactRoot = newReactRoot;
    newDialogueGUI.Parent = player.PlayerGui;

    local conversation = Conversation.getFromDialogue(dialogue);
    local themeModuleScript = dialogue:getSettings().theme.moduleScript or conversation:getSettings().theme.moduleScript or clientSettings.theme.moduleScript;
    local theme = require(themeModuleScript) :: any;
    newReactRoot:render(React.createElement(theme, {
      dialogue = dialogue;
      client = self;
      conversation = conversation;
    }));

  end;

  local function getSettings(self: Client): ClientSettings

    return clientSettings;

  end;

  local function setSettings(self: Client, newSettings: ClientSettings): ()

    clientSettings = newSettings;
    settingsChangedEvent:Fire();

  end;

  local client: Client = {
    cleanup = cleanup;
    getDialogue = getDialogue;
    setDialogue = setDialogue;
    renderDialogue = renderDialogue;
    continueDialogue = continueDialogue;
    getSettings = getSettings;
    setSettings = setSettings;
    setContinueDialogueFunction = setContinueDialogueFunction;
    DialogueChanged = dialogueChangedEvent.Event;
    SettingsChanged = settingsChangedEvent.Event;
  };

  return client;

end;

return Client;