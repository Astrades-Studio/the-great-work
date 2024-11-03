// PreviewRenderingViewport.cs
// Copyright (c) 2023 CookieBadger. All Rights Reserved.

#if TOOLS
#nullable disable
using System;
using System.Collections.Generic;
using System.Diagnostics;
using Godot;
using static AssetPlacer.AssetPreviewGenerator;
using Environment = Godot.Environment;
using Quaternion = Godot.Quaternion;
using Vector3 = Godot.Vector3;

namespace AssetPlacer;

[Tool]
public partial class PreviewRenderingViewport : SubViewport
{
	[Export] private NodePath _cameraPath;
	[Export] private NodePath _lightPath;
	[Export] private NodePath _lightPath2;
	[Export] private NodePath _lightPath3;
	private PreviewCamera3D _camera;
	private Light3D _light;
	private Light3D _light2;
	private Light3D _light3;

	private Node _previewNode;

	private bool _previewReady = false;
	public bool PreviewReady => _previewReady;

	private Perspective _perspectivePreset = Perspective.Front;
	
	// spherical coordinates for easy camera orbit controls
	// X: distance (r) from origin,
	// Y: angle (theta) from Y axis to the position vector,
	// Z: angle (phi) from the X axis to the position vector 
	private Vector3 _sphericalCameraPosition;
	private Transform3D _cameraTransform;
	private Aabb _aabb;
	
	[Signal]
	public delegate void SetupFinishedEventHandler(Vector3 sphericalCameraCoordinates);

	// Called when the node enters the scene tree for the first time.
	public override void _Ready()
	{
		if (!Engine.IsEditorHint()) return;
		RenderTargetClearMode = ClearMode.Always;
		RenderTargetUpdateMode = UpdateMode.Disabled;
		_camera = GetNode<PreviewCamera3D>(_cameraPath);
		_light = GetNode<Light3D>(_lightPath);
		_light2 = GetNode<Light3D>(_lightPath2);
		_light3 = GetNode<Light3D>(_lightPath3);
		_camera.PreviewReady += OnCameraPreviewReady;
		
		// For Testing Spherical Coordinates, and LookAt and stuff
		// Debug.Assert(SphericalToCartesian(new Vector3(0,0,0)).IsEqualApprox(Vector3.Zero));
		// Debug.Assert(SphericalToCartesian(new Vector3(3, 0, 0)).IsEqualApprox(Vector3.Up*3));
		// Debug.Assert(SphericalToCartesian(new Vector3(3, 0, 0.9123f)).IsEqualApprox(Vector3.Up*3));
		// Debug.Assert(SphericalToCartesian(new Vector3(3, Mathf.Pi/2f, 0)).IsEqualApprox(Vector3.Right*3));
		// Debug.Assert(SphericalToCartesian(new Vector3(3, Mathf.Pi/2f, Mathf.Pi/2f)).IsEqualApprox(Vector3.Back*3));
		// Debug.Assert(SphericalToCartesian(new Vector3(3, Mathf.Pi, 0)).IsEqualApprox(Vector3.Down*3));
		//
		// Debug.Assert(Mathf.IsEqualApprox(CartesianToSpherical(Vector3.Zero, Vector3.Zero).X,0));
		// Debug.Assert(CartesianToSpherical(Vector3.Up*3, Vector3.Zero).IsEqualApprox(new Vector3(3, 0, Mathf.Pi/2f)));
		// Debug.Assert(CartesianToSpherical(Vector3.Right*3, Vector3.Zero).IsEqualApprox(new Vector3(3, Mathf.Pi/2f, 0)));
		// Debug.Assert(CartesianToSpherical(Vector3.Back*3, Vector3.Zero).IsEqualApprox(new Vector3(3, Mathf.Pi/2f, Mathf.Pi/2f)));
		// Debug.Assert(CartesianToSpherical(Vector3.Down*3, Vector3.Zero).IsEqualApprox(new Vector3(3, Mathf.Pi, Mathf.Pi/2f)));
	}

	
	public void FreePreviewNode()
	{
		_previewNode?.QueueFree();
		_previewNode = null;
		RenderTargetUpdateMode = UpdateMode.Disabled;
	}

	public void SetPreviewNode(Resource assetResource, Perspective perspective, Vector3 sphericalCameraPosition, bool shadows = false)
	{
		_perspectivePreset = perspective;
		_sphericalCameraPosition = sphericalCameraPosition;
		var previewNode = InstantiateNewAsset(assetResource);
		PreviewNodeSetup(previewNode, shadows);
		RenderTargetUpdateMode = UpdateMode.Always;
	}

	public void UpdateCameraPosition(Vector3 sphericalCameraPosition)
	{
		_camera.Transform = BuildCameraTransform(_aabb, sphericalCameraPosition);
	}

	private Node InstantiateNewAsset(Resource assetResource)
	{
		Node previewNode;
		if (assetResource is PackedScene scene)
		{
			previewNode = scene.Instantiate<Node>();
		}
		else if (assetResource is Mesh mesh)
		{
			MeshInstance3D meshInstance = new MeshInstance3D();
			meshInstance.Mesh = mesh;
			previewNode = meshInstance;
		}
		else
		{
			GD.PrintErr($"{assetResource.ResourceName} can't be displayed.");
			previewNode = new Node3D();
		}
		_previewNode?.QueueFree(); // sanity
		return previewNode;
	}

	private void PreviewNodeSetup(Node node, bool shadows)
	{
		// we parent to a new Node3D and append this to our viewport. This makes sure that even for scenes with a
		// CSG node as a root, the preview works properly
		_updates = 0;
		_previewNode = new Node3D();
		_previewNode.AddChild(node);
		_previewReady = false;
		_previewNode.Ready += RepositionCamera;
		_light.ShadowEnabled = shadows;
		CallDeferred("add_child", _previewNode); // workaround, so _Ready() is not called instantly
	}
	
	private void RepositionCamera()
	{
		if (_previewNode == null) return; // sanity, in case Free is called before this
		_aabb = SpatialUtils.GetGlobalAabb(_previewNode);
		Transform3D transform;
		if (_perspectivePreset == Perspective.Custom)
		{
			transform = BuildCameraTransform(_aabb, _sphericalCameraPosition);
		}
		else
		{
			transform = CalculateCameraTransformFromPreset(_aabb, _perspectivePreset);
			_sphericalCameraPosition = CartesianToSpherical(transform.Origin - _aabb.GetCenter(), transform.Basis.GetEuler());
		}
		_camera.StartPreview(transform);
		_light.Quaternion = _camera.Quaternion * Quaternion.FromEuler(new Vector3(-1.047198f, 0.7853982f,0)); // -60, 45, 0) // Key Light
		_light2.Quaternion = _camera.Quaternion * Quaternion.FromEuler(new Vector3(-0.2617994f, -0.7853982f,2.007129f)); // -15, -45, 115 // Fill Light
		_light3.Quaternion = _camera.Quaternion * Quaternion.FromEuler(new Vector3(0.2617994f, 2.356194f,2.007129f)); // 15, 135, 115// Back Light
		EmitSignal(SignalName.SetupFinished, _sphericalCameraPosition);
	}

	private int _updates = 0;
	private void OnCameraPreviewReady()
	{
		_previewReady = true;
	}

	private static Transform3D BuildCameraTransform(Aabb aabb, Vector3 sCamPos)
	{
		var relativePosition = SphericalToCartesian(sCamPos);
		var position = aabb.GetCenter() + relativePosition;
		if (Mathf.Abs(relativePosition.LengthSquared()) < Mathf.Epsilon)
			return new Transform3D(Basis.Identity, position);
		
		var basis = LookAt(relativePosition.Normalized(), sCamPos.Z);
		return new Transform3D(basis, position);
	}
	
	// Calculates how the camera should be transformed, such that it frames the object in a useful way.
	private Transform3D CalculateCameraTransformFromPreset(Aabb aabb, Perspective perspective)
	{
		var enclosingSquare = GetAabbEnclosingSquareSize(aabb, perspective);
		
		// The smaller the object, the farther away the camera (relatively) to give a sense of scale.
		const float sizeRlerpMin = 0.1f;
		const float sizeRlerpMax = 100f;
		var rangeVal = Mathf.Clamp(enclosingSquare, sizeRlerpMin, sizeRlerpMax);
		var logRangeVal = LogLerp(sizeRlerpMin, sizeRlerpMax, rangeVal); // BETWEEN 0 AND 1
		var objectSizeFactor = Mathf.Lerp(0.5f, 2.5f, 1f-logRangeVal); // 0.25 - 2 logarithmically lerped
		
		// very big objects are viewed from 0.25 times the aabb size outside of the aabb
		// whereas small objects are viewed from 1.5 times the aabb size outside of the aabb
		var distance = (GetAabbDepth(aabb, perspective) / 2f) + (enclosingSquare / 2f) * objectSizeFactor;

		var sCamPos = GetSphericalCoords(distance, perspective);
	
		var relativePosition = SphericalToCartesian(sCamPos);
		var position = aabb.GetCenter() + relativePosition;
		if (Mathf.Abs(relativePosition.LengthSquared()) < Mathf.Epsilon)
			return new Transform3D(Basis.Identity, position);
	
		var basis = LookAt(relativePosition.Normalized(), sCamPos.Z);
		return new Transform3D(basis, position);
	}

	private static Vector3 GetSphericalCoords(float distance, Perspective perspective)
	{
		var horizontalDegrees = Settings.GetSetting(Settings.DefaultCategory, PerspectiveAngleHorizontalSetting).AsSingle();
		var horizontalAngle = Mathf.DegToRad(horizontalDegrees);
		var verticalDegrees = Settings.GetSetting(Settings.DefaultCategory, PerspectiveAngleVerticalSetting).AsSingle();
		var verticalAngle = Mathf.DegToRad(verticalDegrees);
		
		switch (perspective)
		{
			case Perspective.Front: return new Vector3(distance, Mathf.Pi/2f - verticalAngle, Mathf.Pi/2f - horizontalAngle);
			case Perspective.Back: return new Vector3(distance, Mathf.Pi/2f - verticalAngle, -Mathf.Pi/2f - horizontalAngle);
			case Perspective.Left: return new Vector3(distance, Mathf.Pi/2f - verticalAngle, Mathf.Pi - horizontalAngle);
			case Perspective.Right: return new Vector3(distance,  Mathf.Pi/2f - verticalAngle, 0f - horizontalAngle);
			case Perspective.Top: return new Vector3(distance, 0f, Mathf.Pi/2f);
			case Perspective.Bottom: return new Vector3(distance, Mathf.Pi, Mathf.Pi/2f);
			default: return Vector3.Zero;
		}
	}

	private static Basis LookAt(Vector3 back, float phi)
	{
		var up = Vector3.Up;
		if (back.IsEqualApprox(Vector3.Up)) up = Vector3.Forward; // should be capped somewhere at the zenith
		if (back.IsEqualApprox(Vector3.Down)) up = Vector3.Back;
		var right = up.Cross(back);
		
		if (back.IsEqualApprox(Vector3.Up)) right = right.Rotated(Vector3.Up, -phi+Mathf.Pi/2f); 
		if (back.IsEqualApprox(Vector3.Down)) right = right.Rotated(Vector3.Up, -phi+Mathf.Pi/2f);
		
		return new Basis(right, back.Cross(right), back);
	}

	private static Vector3 SphericalToCartesian(Vector3 sphericalCoords)
	{
		// x = r sin(theta) cos(phi)
		// y = r cos(theta)
		// z = r sin(theta) sin(phi)
		return new Vector3(Mathf.Sin(sphericalCoords.Y)*Mathf.Cos(sphericalCoords.Z), Mathf.Cos(sphericalCoords.Y), Mathf.Sin(sphericalCoords.Y)*Mathf.Sin(sphericalCoords.Z))*sphericalCoords.X;
	}
	
	private static Vector3 CartesianToSpherical(Vector3 cartesian, Vector3 rotation)
	{
		var len = cartesian.Length();
		if (Math.Abs(len) < Mathf.Epsilon) return new Vector3(len, rotation.X+Mathf.Pi/2f, -rotation.Y+Mathf.Pi/2f);
		
		var planeLen = new Vector2(cartesian.X, cartesian.Z).Length();
		if (Math.Abs(planeLen) < Mathf.Epsilon) return new Vector3(len, cartesian.Y > 0 ? 0 : Mathf.Pi, -rotation.Y+Mathf.Pi/2f);
		
		return new Vector3(
			len, 
			Mathf.Acos(cartesian.Y/len), // arccos(y/length)
			Mathf.Sign(cartesian.Z)*Mathf.Acos(cartesian.X/planeLen)); //sgn(z)arccos(x/length([x,z]))
	}
	
	private static Vector3 GetRotationEuler(Aabb aabb, float distance, float sideFactor, Perspective perspective)
	{
		var perspectiveOffset = 0f;
		var sign = 1f;
		switch (perspective)
		{	
			case Perspective.Bottom: return new Vector3(Mathf.Pi / 2f, 0, 0);
			case Perspective.Top: return new Vector3(-Mathf.Pi / 2f, 0, 0);
			case Perspective.Front: perspectiveOffset = 0f; break;
			case Perspective.Back: perspectiveOffset = Mathf.Pi; break;
			case Perspective.Left: 
				perspectiveOffset = -Mathf.Pi/2;
				sign = -1f; 
				break;
			case Perspective.Right: 
				perspectiveOffset = Mathf.Pi/2;
				sign = -1f; 
				break;
		}
		
		var hypot = Mathf.Sqrt(Mathf.Pow(distance, 2) + Mathf.Pow(distance * sideFactor, 2));
		return new Vector3(-Mathf.Atan((aabb.Size.Y / 4f) / hypot), perspectiveOffset + sign * Mathf.Atan(sideFactor), 0);
	}

	private static float GetAabbDepth(Aabb aabb, Perspective perspective)
	{
		return perspective switch
		{
			Perspective.Front => aabb.Size.Z,
			Perspective.Back => aabb.Size.Z,
			Perspective.Top => aabb.Size.Y,
			Perspective.Bottom => aabb.Size.Y,
			Perspective.Left => aabb.Size.X,
			Perspective.Right => aabb.Size.X,
			_ => 0f
		};
	}

	private static float GetAabbEnclosingSquareSize(Aabb aabb, Perspective perspective)
	{
		// depending on the side that we are looking at the object from, the enclosing square is at least as large as
		// the larger of the two other dimensions
		// e.g. if we are looking from the Z direction, we are not interested in how long the object is (Z-size)

		return perspective switch
		{
			Perspective.Front => Mathf.Max(aabb.Size.X, aabb.Size.Y),
			Perspective.Back => Mathf.Max(aabb.Size.X, aabb.Size.Y),
			Perspective.Top => Mathf.Max(aabb.Size.X, aabb.Size.Z),
			Perspective.Bottom => Mathf.Max(aabb.Size.X, aabb.Size.Z),
			Perspective.Left => Mathf.Max(aabb.Size.Y, aabb.Size.Z),
			Perspective.Right => Mathf.Max(aabb.Size.Y, aabb.Size.Z),
			_ => 0f
		};
	}

	// Logarithmic interpolation between minVal and maxVal, where value=minVal returns 0 and value=maxVal returns 1.
	private static float LogLerp(float minVal, float maxVal, float value)
	{
		var p = Mathf.Pow(10, -Mathf.Log(minVal));
		return Mathf.Log(value * p) / Mathf.Log(maxVal * p);
	}
}
#endif
