// InputManager.cs
// Copyright (c) 2023 CookieBadger. All Rights Reserved.

#if TOOLS
#nullable disable
using System.Collections.Generic;
using Godot;

namespace AssetPlacer;

[Tool]
public partial class InputManager : GodotObject
{
	public static readonly Key CancelKey = Key.Escape;
	public static readonly List<Key> MovementKeys = new List<Key>() { Key.W, Key.A, Key.S, Key.D, Key.E, Key.Q,};
	public static readonly List<Key> ConfirmKeys = new List<Key>() { Key.Space, Key.Enter};
	
	public enum InputEventType
	{ Placement, AltPlacement, Cancel, Movement, Confirm, Other }
	
	public static bool lmbPressed;
	public static bool rmbPressed;
	public static bool shiftPressed;
	public static bool ctrlPressed;
	public static bool altPressed;
	
	public Vector2 screenMousePosition;
	public Vector2 viewportMousePos = new Vector2(0.5f, 0.5f);
	public Rect2 tooltipRect;
	
	private List<Key> pressedKeys = new();

	public void _ForwardInput(InputEvent @event)
	{
		if (@event is InputEventMouseButton mouse)
		{
			if (mouse.ButtonIndex == MouseButton.Right && !mouse.IsPressed())
			{
				rmbPressed = false;
			}
		}
	}
	
	public InputEventType DetermineInputEventType(InputEvent @event)
	{
		InputEventType inputEventType = InputEventType.Other;
		if (@event is InputEventMouse mouseEvent)
		{
			shiftPressed = mouseEvent.ShiftPressed;
			ctrlPressed = mouseEvent.CtrlPressed;
			altPressed = mouseEvent.AltPressed;
		} else if (@event is InputEventKey modifierKey)
		{
			if(modifierKey.Keycode == Key.Shift) shiftPressed = modifierKey.Pressed;
			if(modifierKey.Keycode == Key.Ctrl) ctrlPressed = modifierKey.Pressed;
			if(modifierKey.Keycode == Key.Alt) altPressed = modifierKey.Pressed;
		}
		
		if (@event is InputEventMouseButton mouseButtonEvent)
		{
			switch (mouseButtonEvent.ButtonIndex)
			{
				case MouseButton.Right:
					rmbPressed = mouseButtonEvent.IsPressed();
					break;
				case MouseButton.Left:
					if(mouseButtonEvent.IsPressed() && !lmbPressed) {
						inputEventType = InputEventType.Placement; // lmb was just pressed down this frame 
						var isAlt = Settings.GetSetting(Settings.DefaultCategory, Settings.UseShiftSetting).AsBool() ? mouseButtonEvent.ShiftPressed : mouseButtonEvent.AltPressed;
						if (isAlt) inputEventType = InputEventType.AltPlacement;
					}
					lmbPressed = mouseButtonEvent.IsPressed();
					break;
			}
		} else if(@event is InputEventKey key) {
			if (key.Keycode == CancelKey && key.Pressed)
			{
				inputEventType = InputEventType.Cancel;
			} else if (ConfirmKeys.Contains(key.Keycode) && key.Pressed)
			{
				inputEventType = InputEventType.Confirm;
			}else if (MovementKeys.Contains(key.Keycode))
			{
				inputEventType = InputEventType.Movement;
				switch (key.Pressed)
				{
					case true when !pressedKeys.Contains(key.Keycode):
						pressedKeys.Add(key.Keycode);
						break;
					case false when pressedKeys.Contains(key.Keycode):
						pressedKeys.Remove(key.Keycode);
						break;
				}
			}
		}

		return inputEventType;
	}

	public void _Forward3DViewportInput(Viewport viewport, InputEvent @event)
	{
		if (@event is InputEventMouse mouse && !rmbPressed)
		{
			screenMousePosition = mouse.Position + viewport.GetScreenTransform().Origin;
			viewportMousePos =  (mouse.Position) / (viewport.GetVisibleRect().Size * viewport.GetScreenTransform().Scale);
			tooltipRect = new Rect2(viewport.GetScreenTransform().Origin, viewport.GetVisibleRect().Size * viewport.GetScreenTransform().Scale);
		}
	}
}
#endif