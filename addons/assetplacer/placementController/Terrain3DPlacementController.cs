// Terrain3DPlacementController.cs
// Copyright (c) 2023 CookieBadger. All Rights Reserved.

#if TOOLS
#nullable disable
using System;
using System.Collections.Generic;
using Godot;

namespace AssetPlacer;

public partial class Terrain3DPlacementController : SurfacePlacementController
{
	public Terrain3DPlacementController()
	{
	}
	
	public Terrain3DPlacementController(PlacementUi placementUi, Snapping snapping, EditorInterface editorInterface, Node root) : base(placementUi, snapping, editorInterface, root)
	{
	}
	
	public override PlacementInfo GetPlacementPosition(Camera3D viewportCam, Vector2 viewportMousePosition, List<Node3D> placingNodes)
	{
		var _terrain3DNode = placementUi._terrain3DSelector.Node;
		if(viewportCam == null) return new PlacementInfo(PlacementPositionInfo.invalidInfo);
		if(_terrain3DNode == null) return new PlacementInfo(PlacementPositionInfo.invalidInfo, "Assign Terrain3D Node!", Colors.Red);
		var from = viewportCam.ProjectRayOrigin(viewportMousePosition * viewportCam.GetViewport().GetVisibleRect().Size);
		var dir = viewportCam.ProjectRayNormal(viewportMousePosition * viewportCam.GetViewport().GetVisibleRect().Size);

		var data = _terrain3DNode.Call("get_data");
		if (data.Obj == null)
		{
			data = _terrain3DNode.Get("storage"); // legacy (>0.9.3)
			if (data.Obj == null)
			{
				return new PlacementInfo(PlacementPositionInfo.invalidInfo, "Error retrieving Terrain3D data", Colors.Red);	
			}
		}
		var heightRange = data.As<GodotObject>().Call("get_height_range");
		if (heightRange.Obj == null)
		{
			heightRange = data.As<Resource>().Get("height_range"); // legacy (>0.9.3)
			if (heightRange.Obj == null)
			{
				return new PlacementInfo(PlacementPositionInfo.invalidInfo, "Error retrieving Terrain3D height range", Colors.Red);	
			}
		}
		
		if (viewportCam.Projection == Camera3D.ProjectionType.Orthogonal)
		{
			from = OrthogonalClamp(from, dir, heightRange.AsVector2());
		}
		
		var intersectionVar = _terrain3DNode.Call("get_intersection", from, dir);
		if (intersectionVar.Obj == null)
		{
			return new PlacementInfo(PlacementPositionInfo.invalidInfo, "Error retrieving Intersection with Terrain3D", Colors.Red);
		}

		var intersection = intersectionVar.AsVector3();
		if (intersection.X >= 3.4e38) // no intersection
		{
			return new PlacementInfo(PlacementPositionInfo.invalidInfo, "Hover over Terrain3D to place");
		}
        
		var pos = intersection;
		var normalVar = data.As<GodotObject>().Call("get_normal", intersection);
		if (normalVar.Obj == null)
		{
			return new PlacementInfo(PlacementPositionInfo.invalidInfo, "Error retrieving Terrain3D Normal", Colors.Red);
		}
		var normal = normalVar.AsVector3();
		if (Mathf.IsNaN(normal.X) && Mathf.IsNaN(normal.Y) && Mathf.IsNaN(normal.Z))
		{
			normal = Vector3.Up;
		} else if (normal.LengthSquared() < Mathf.Epsilon || Mathf.IsNaN(normal.X) || Mathf.IsNaN(normal.Y) || Mathf.IsNaN(normal.Z))
		{
			return new PlacementInfo(PlacementPositionInfo.invalidInfo, "Error retrieving Terrain3D Normal", Colors.Red);
		}
		
		var placementInfo = new SurfacePlacementPositionInfo(pos, true, placementUi.AlignWithSurfaceNormal, normal, placementUi.AlignmentDirection);

		if (placementInfo.posValid)
		{
			var (gridPos, gridRot) = GetGridTransform(placementInfo);
			snapping.UpdateGridTransform(gridPos, viewportCam.Projection == Camera3D.ProjectionType.Perspective, gridRot);
		}
		
		_lastValidPlacementInfo = placementInfo;
		if(placementInfo.posValid) snapping.HideGrid(false);
		//return new PlacementInfo(PlacementPositionInfo.invalidInfo, $"{from}, {dir}, {intersection}", Colors.Red);
		return new PlacementInfo(placementInfo);
	}

	private Vector3 OrthogonalClamp(Vector3 from, Vector3 dir, Vector2 heightRange)
	{
		const int distance = 30;
		if (from.Y > 1 && dir.Y < 0) // looking from above
		{
			var m = heightRange.Y + distance;
			var t = (m - from.Y) / dir.Y;

			return from + dir * t;
		}
		else if (from.Y < -1 && dir.Y > 0) // looking from below
		{
			var m = heightRange.X - distance;
			var t = (m - from.Y) / dir.Y;

			return from + dir * t;
		}
		return from;
	}
}
#endif
