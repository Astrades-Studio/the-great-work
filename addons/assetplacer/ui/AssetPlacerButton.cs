// AssetPlacerButton.cs
// Copyright (c) 2023 CookieBadger. All Rights Reserved.

#if TOOLS
#nullable disable
using System;
using Godot;

namespace AssetPlacer;

/**
 * Class for the asset buttons. Purely for event/signal handling.
 * On rebuilding, any custom C# event Actions get disconnected.
 * Built-in event actions that are connected to an anonymous lambda with captured variables
 * are then null, which is bad. Very bad.
 */
[Tool]
public partial class AssetPlacerButton : Button
{
	public const Key ToggleDynamicPreviewKey = Key.V;

	public enum ButtonType
	{ 
		Normal, Mesh
	}

	public ButtonType type = ButtonType.Normal; 
	public string assetPath;
	public string assetName;
	public bool isBroken = false;
	[Export] public NodePath iconTextureRect;
	[Export] public NodePath resetTransformButton;
	private TextureRect _iconTextureRect;
	private Button _resetTransformButton;
	
	[Signal]
	public delegate void RightClickedEventHandler(string assetPath, Vector2 clickPosition);
	
	[Signal]
	public delegate void ButtonWasPressedEventHandler(AssetPlacerButton button);
	
	[Signal]
	public delegate void ResetTransformPressedEventHandler(AssetPlacerButton button, string assetPath);

	[Signal]
	public delegate void ShowDynamicPreviewEventHandler(string assetPath);
	public override void _Ready()
	{
		Pressed += OnPressed;
		GuiInput += OnGuiInput;
		_iconTextureRect = GetNode<TextureRect>(iconTextureRect);
		_resetTransformButton = GetNode<Button>(resetTransformButton);
		_resetTransformButton.Pressed += OnResetTransform;
	}

	public void SetData(string assetPath, string assetName)
	{
		this.assetPath = assetPath;
		this.assetName = assetName;
	}

	public void SetButtonType(ButtonType type)
	{
		this.type = type;
	}

	public void UpdateButtonIcon(Texture2D meshIcon) // add icon parameters if more button types are created
	{
		switch (type)
		{
			case ButtonType.Mesh:
				_iconTextureRect.Texture = meshIcon;
				break;
			case ButtonType.Normal:
				_iconTextureRect.Texture = null;
				break;
		}
	}

	public void OnGuiInput(InputEvent @event)
	{
		if (@event is InputEventMouseButton rightMouseButton && rightMouseButton.ButtonMask == MouseButtonMask.Right)
			EmitSignal(SignalName.RightClicked, assetPath, GetScreenPosition() + rightMouseButton.Position);
	}

	public override void _Input(InputEvent @event)
	{
		if (!Engine.IsEditorHint()) return;

		// Activate Dynamic Preview
		if (@event is InputEventKey keyEvent)
		{
			if (keyEvent.Keycode == ToggleDynamicPreviewKey && keyEvent.Pressed && IsHovered() && !keyEvent.IsEcho())
			{
				EmitSignal(SignalName.ShowDynamicPreview, assetPath);
				GetTree().Root.SetInputAsHandled();
			}
		}
			
	}

	public void OnPressed()
	{
		EmitSignal(SignalName.ButtonWasPressed, this);
	}

	public void OnResetTransform()
	{
		EmitSignal(SignalName.ResetTransformPressed, this, assetPath);
	}

	public void SetResetTransformButtonVisible(bool visible)
	{
		_resetTransformButton.Visible = visible;
	}

	public void SetChildButtonTheme(Theme buttonTheme)
	{
		_resetTransformButton.Theme = buttonTheme;
	}
}
#endif
