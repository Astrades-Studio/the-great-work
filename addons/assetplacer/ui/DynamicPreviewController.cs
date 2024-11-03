// DynamicPreviewController.cs
// Copyright (c) 2024 CookieBadger. All Rights Reserved.

#if TOOLS
#nullable disable

using Godot;

namespace AssetPlacer;

[Tool]
public partial class DynamicPreviewController : GodotObject
{
	public Vector3 SphericalCameraCoordinates { get; private set; }

	public bool Active { get; private set; }

	private float _targetR;
	private float _targetTheta;
	private float _targetPhi;

	private EditorSettings _editorSettings;

	private float _translationInertia;
	private float _zoomInertia;
	private float _orbitSensitivity; // radians per pixel
	private bool _invertXAxis;
	private bool _invertYAxis;

	private Vector2 _lastOrbitMousePos;
	private bool _orbiting;
	public bool HasChanged { get; private set; }

	public void Activate(Vector3 sphericalCameraCoordinates, EditorSettings editorSettings)
	{
		SphericalCameraCoordinates = sphericalCameraCoordinates;
		Active = true;
		_targetR = SphericalCameraCoordinates.X;
		_targetTheta = SphericalCameraCoordinates.Y;
		_targetPhi = SphericalCameraCoordinates.Z;
		_editorSettings = editorSettings;
		HasChanged = false;
		
		_invertXAxis = _editorSettings.GetSetting("editors/3d/navigation/invert_x_axis").AsBool();
		_invertYAxis = _editorSettings.GetSetting("editors/3d/navigation/invert_y_axis").AsBool();
		_translationInertia = _editorSettings.GetSetting("editors/3d/navigation_feel/translation_inertia").AsSingle();
		_zoomInertia = _editorSettings.GetSetting("editors/3d/navigation_feel/zoom_inertia").AsSingle();
		_orbitSensitivity = Mathf.DegToRad(_editorSettings.GetSetting("editors/3d/navigation_feel/orbit_sensitivity").AsSingle());
	}

	public void Deactivate()
	{
		Active = false;
	}

	public void Process(double delta)
	{
		var theta = Mathf.Lerp(SphericalCameraCoordinates.Y, _targetTheta, Mathf.Min(1f, (float) delta * (1f / _translationInertia)));
		var phi = Mathf.Lerp(SphericalCameraCoordinates.Z, _targetPhi, Mathf.Min(1f, (float) delta * (1f / _translationInertia)));
		
		 var r = Mathf.Lerp(SphericalCameraCoordinates.X, _targetR, Mathf.Min(1f, (float) delta * (1f / _zoomInertia)));
		 SphericalCameraCoordinates = new Vector3(r, theta, phi);
	}
	
	public bool HandleInput(InputEvent @event, Control panel)
	{
		if (!Active) return false;

		// if mmb is pressed, rotate the asset
		if (@event is InputEventMouseMotion motion)
		{
			// Grab focus if mouse passes over the panel
			if (panel.GetGlobalRect().HasPoint(motion.GlobalPosition))
			{
				panel.GrabFocus();
			}
			
			// if we started orbiting, we don't care if we have focus or not
			if (_orbiting && motion.ButtonMask.HasFlag(MouseButtonMask.Middle))
			{
				var relative = motion.Position - _lastOrbitMousePos;
				_lastOrbitMousePos = motion.Position;
				if (_invertYAxis) {
					_targetTheta += relative.Y * _orbitSensitivity;
				} else {
					_targetTheta -= relative.Y * _orbitSensitivity;
				}
				_targetTheta = Mathf.Clamp(_targetTheta, 0.00f, Mathf.Pi-0.0f);
			    
				if (_invertXAxis) {
					_targetPhi -= relative.X * _orbitSensitivity;
				} else {
					_targetPhi += relative.X * _orbitSensitivity;
				}

				WarpMouseInRect(panel.GetGlobalRect(), motion.GlobalPosition);
				HasChanged = true;
				return true;
			}
		}
		
		if (!panel.HasFocus()) return false;
		if (@event is InputEventMouseButton button)
		{
			if (button.ButtonIndex == MouseButton.Middle && !button.IsEcho())
			{
				if (button.Pressed)
				{
					_lastOrbitMousePos = button.Position;
				}
				_orbiting = button.Pressed; // orbiting has to start in focus
			}
			// zoom with mouse wheel
			if (button.ButtonIndex == MouseButton.WheelUp)
			{
				OnWheel(-1f);
				HasChanged = true;
				return true;
			} 
			if (button.ButtonIndex == MouseButton.WheelDown)
			{
				OnWheel(1f);
				HasChanged = true;
				return true;
			}
		}

	    return false;
    }

	private void WarpMouseInRect(Rect2 globalPanelRect, Vector2 globalMousePosition)
	{
		bool warp = false;
		Vector2 warpPos = globalMousePosition;
		if (globalMousePosition.X < globalPanelRect.Position.X)
		{
			warp = true;
			warpPos.X = globalPanelRect.Position.X + globalPanelRect.Size.X;
			_lastOrbitMousePos.X += globalPanelRect.Size.X;
		}
		else if (globalMousePosition.X > globalPanelRect.Position.X + globalPanelRect.Size.X)
		{
			warp = true;
			warpPos.X = globalPanelRect.Position.X;
			_lastOrbitMousePos.X -= globalPanelRect.Size.X;
		}

		if (globalMousePosition.Y < globalPanelRect.Position.Y)
		{
			warp = true;
			warpPos.Y = globalPanelRect.Position.Y + globalPanelRect.Size.Y;
			_lastOrbitMousePos.Y += globalPanelRect.Size.Y;
		}
		else if (globalMousePosition.Y > globalPanelRect.Position.Y + globalPanelRect.Size.Y)
		{
			warp = true;
			warpPos.Y = globalPanelRect.Position.Y;
			_lastOrbitMousePos.Y -= globalPanelRect.Size.Y;
		}

		if (warp)
		{
			Input.WarpMouse(warpPos);
		}
	}

	private void OnWheel(float sign)
	{
		var log = Mathf.Log(_targetR);
		log = Mathf.Round(log*20f)/20f;
		_targetR = Mathf.Clamp(Mathf.Exp(log + sign*0.05f), 0.2f, 1000f);
	}
}
#endif