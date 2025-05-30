--!strict

local Players = game:GetService("Players");

local packages = script.Parent.roblox_packages;
local React = require(packages.react);
local ReactRoblox = require(packages["react-roblox"]);
local IClient = require(packages.client_types);
local IConversation = require(packages.conversation_types);
local IDialogue = require(packages.dialogue_types);

type Dialogue = IDialogue.Dialogue;
type Client = IClient.Client;
type ClientSettings = IClient.ClientSettings;
type Conversation = IConversation.Conversation;
type ConstructorClientSettings = IClient.ConstructorClientSettings;

local Client = {
  sharedClient = nil :: Client?;
  defaultSettings = {
    general = {
      shouldEndConversationOnCharacterRemoval = true;
    };
    responses = {
      clickSound = nil;
    };
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

function Client.new(clientSettings: ConstructorClientSettings): Client

  local player = Players.LocalPlayer;
  local conversation: Conversation? = nil;
  local settings: ClientSettings = {
    general = {
      theme = clientSettings.general.theme;
      shouldEndConversationOnCharacterRemoval = if clientSettings and clientSettings.general and clientSettings.general.shouldEndConversationOnCharacterRemoval then clientSettings.general.shouldEndConversationOnCharacterRemoval else Client.defaultSettings.general.shouldEndConversationOnCharacterRemoval;
    };
    responses = {
      clickSound = if clientSettings and clientSettings.responses then clientSettings.responses.clickSound else Client.defaultSettings.responses.clickSound;
    };
    keybinds = {
      interactKey = if clientSettings and clientSettings.keybinds then clientSettings.keybinds.interactKey else Client.defaultSettings.keybinds.interactKey; 
      interactKeyGamepad = if clientSettings and clientSettings.keybinds then clientSettings.keybinds.interactKeyGamepad else Client.defaultSettings.keybinds.interactKeyGamepad; 
    };
  };

  local settingsChangedEvent = Instance.new("BindableEvent");
  local conversationChangedEvent = Instance.new("BindableEvent");

  local function freezePlayer(self: Client): ()
  
    (require(player.PlayerScripts:WaitForChild("PlayerModule")) :: any):GetControls():Disable();
    
  end;

  local function getConversation(self: Client): Conversation?

    return conversation;

  end;

  local function setConversation(self: Client, newConversation: Conversation?): ()

    conversation = newConversation;
    conversationChangedEvent:Fire();

  end;

  local function interact(self: Client, newConversation: Conversation)

    -- Make sure we aren't already talking to an NPC
    assert(not conversation, "[Dialogue Maker] Cannot read dialogue because player is currently talking with another NPC.");
    self:setConversation(newConversation);
    
    -- Freeze the player if the dialogue server has a setting for it.
    local conversationSettings = newConversation:getSettings();
    local shouldFreezePlayer = conversationSettings.general.shouldFreezePlayer;
    if shouldFreezePlayer then 

      self:freezePlayer(); 

    end;

    -- Initialize the theme, then listen for changes
    local themeModuleScript = conversationSettings.general.theme or settings.general.theme;
    local dialogueGUI = Instance.new("ScreenGui");
    local root = ReactRoblox.createRoot(dialogueGUI);
    dialogueGUI.Parent = player.PlayerGui;

    -- Start the dialogue loop.
    local queue = newConversation:getChildren();
    local priorityIndex = 1;

    while conversation and task.wait() do

      local dialogue = queue[priorityIndex];
      if not dialogue then

        break;

      end

      if dialogue:verifyCondition() then
        
        if dialogue.redirectModuleScript then

          local parent = dialogue.redirectModuleScript.Parent;
          local parentDialogue = require(parent) :: Dialogue;
          queue = parentDialogue:getChildren();
          local newPriorityIndex: number? = nil;

          for index, childDialogue in queue do

            if childDialogue.moduleScript == dialogue.redirectModuleScript then

              newPriorityIndex = index;
              break;

            end;

          end;

          assert(newPriorityIndex, "[Dialogue Maker] Could not find redirect dialogue in queue.");
          priorityIndex = newPriorityIndex;
          
          continue;

        end;
        
        -- Run the dialogue's initialization action.
        dialogue:runAction(1);

        -- Show the dialogue to the player.
        local completionEvent = Instance.new("BindableEvent");
        local function renderRoot()

          root:render(React.createElement(require(themeModuleScript) :: any, {
            dialogue = dialogue;
            onComplete = function(newParent: Dialogue?)
        
              -- Run the dialogue's completion action.
              dialogue:runAction(2);
    
              -- Continue through the dialogue tree.
              local parent = newParent or dialogue;
              queue = parent:getChildren();
              priorityIndex = 1;
              completionEvent:Fire(false);
        
            end;
            onTimeout = function()
    
              completionEvent:Fire(true);
    
            end;
            client = self;
            conversation = conversation;
          }));

        end;

        local settingsChangedSignal = self.SettingsChanged:Connect(function()

          if settings.general.theme ~= themeModuleScript then

            themeModuleScript = settings.general.theme;
            renderRoot();

          end;
      
        end);

        renderRoot();
        
        local didTimeout = completionEvent.Event:Wait();
        if didTimeout then

          break;

        end;

        settingsChangedSignal:Disconnect();

      else

        -- There is a message; however, the player failed the condition.
        -- Let's check if there's something else available.
        priorityIndex += 1;

      end;

    end;

    -- No more dialogue to show, so let's clean up.
    if freezePlayer then 

      self:unfreezePlayer(); 

    end;

    root:unmount();
    dialogueGUI:Destroy();
    self:setConversation();

  end;

  local function unfreezePlayer(self: Client): ()

    (require(player.PlayerScripts:WaitForChild("PlayerModule")) :: any):GetControls():Enable();
    
  end;

  local function getSettings(self: Client): ClientSettings

    return table.clone(settings);

  end;

  local function setSettings(self: Client, newSettings: ClientSettings): ()

    clientSettings = newSettings;
    settingsChangedEvent:Fire();

  end;

  local client: Client = {
    freezePlayer = freezePlayer;
    interact = interact;
    getSettings = getSettings;
    setSettings = setSettings;
    unfreezePlayer = unfreezePlayer;
    getConversation = getConversation;
    setConversation = setConversation;
    SettingsChanged = settingsChangedEvent.Event;
    ConversationChanged = conversationChangedEvent.Event;
  };

  player.CharacterRemoving:Connect(function()

    conversation = nil;

  end);

  client.SettingsChanged:Connect(function()
  
  end);

  return client;

end;

return Client;