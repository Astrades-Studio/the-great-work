// SpatialUtils.cs
// Copyright (c) 2024 CookieBadger. All Rights Reserved.

using System.Collections.Generic;
using Godot;

namespace AssetPlacer;

public static class SpatialUtils
{
	public static void OrganizeSpatialChildren(Node3D root)
    {
	    // measure all assets
	    var totalArea = 0f;
	    var totalSize = Vector3.Zero;
	    var nodeAabbs = new Dictionary<Node3D, Aabb>();
	    var assetCount = 0;
	    foreach (var node in root.GetChildren())
	    {
		    if (node is Node3D node3D)
		    {
			    var aabb = GetGlobalAabb(node);
			    totalArea += aabb.Size.X * aabb.Size.Z;
			    totalSize += aabb.Size;
			    nodeAabbs[node3D] = aabb;
			    assetCount++;
		    }
	    }

	    // position all assets
	    var averageAssetX = totalSize.X / assetCount;
	    var averageAssetZ = totalSize.Z / assetCount;
	    var paddingX = averageAssetX / 2f; // paddings are average asset sizes
	    var paddingZ = averageAssetZ / 2f;
	    var tightRowLength = Mathf.Sqrt(totalArea);
	    var desiredAssetsPerRow = tightRowLength / averageAssetX;
	    var desiredAssetsPerColumn = assetCount / desiredAssetsPerRow;
	    var desiredRowLength = tightRowLength + (desiredAssetsPerRow - 1) * paddingX; // row length plus padding
	    var desiredZ = desiredAssetsPerColumn * averageAssetZ + (desiredAssetsPerColumn - 1) * paddingZ;
	    var currentRowDepth = 0f;
	    var x = 0f;
	    var z = 0f;

	    foreach (var node in nodeAabbs.Keys)
	    {
		    if (x > desiredRowLength)
		    {
			    z += currentRowDepth + paddingZ;
			    x = 0f;
			    currentRowDepth = 0f;
		    }

		    var sizeX = nodeAabbs[node].Size.X;
		    var sizeZ = nodeAabbs[node].Size.Z;
		    var position = new Vector3(-desiredRowLength / 2f + x, 0f, -desiredZ / 2f + z);
		    //var position = new Vector3( + x, 0f,  + z);
		    var center = nodeAabbs[node].GetCenter();
		    node.Position = position - new Vector3(center.X, 0f, center.Z) + new Vector3(sizeX / 2f, 0f, sizeZ / 2f);

		    x += sizeX + paddingX;
		    currentRowDepth = Mathf.Max(sizeZ, currentRowDepth);
	    }
    }

	public static Aabb GetGlobalAabb(Node root)
	{
		var endpoints = new List<Vector3>();
		GetAabbEndpointsRecursive(root, endpoints);
		Vector3 start = Vector3.Zero;
		Vector3 end = Vector3.Zero;
		
		if (endpoints.Count > 0)
		{
			start = endpoints[0];
			end = endpoints[0];
		}
		
		foreach (var endpoint in endpoints)
		{
			if (endpoint.X < start.X) start.X = endpoint.X;
			if (endpoint.Y < start.Y) start.Y = endpoint.Y;
			if (endpoint.Z < start.Z) start.Z = endpoint.Z;

			if (endpoint.X > end.X) end.X = endpoint.X;
			if (endpoint.Y > end.Y) end.Y = endpoint.Y;
			if (endpoint.Z > end.Z) end.Z = endpoint.Z;
		}

		return new Aabb(start, end - start);
	}

	private static void GetAabbEndpointsRecursive(Node currentNode, List<Vector3> endpoints)
	{
		if (currentNode is VisualInstance3D instance3D)
		{
			var globalAabbEndpoints = GetGlobalAabbEndpoints(instance3D);
			endpoints.AddRange(globalAabbEndpoints);
		}

		foreach (var child in currentNode.GetChildren())
		{
			GetAabbEndpointsRecursive(child, endpoints);
		}
	}

	private static Vector3[] GetGlobalAabbEndpoints(VisualInstance3D visualInstance3D)
	{
		var globalEndpoints = new Vector3[8];
		var localAabb = visualInstance3D.GetAabb();
		for (int i = 0; i < 8; i++)
		{
			var local_endpoint = localAabb.GetEndpoint(i);
			var global_endpoint = visualInstance3D.ToGlobal(local_endpoint);
			globalEndpoints[i] = global_endpoint;
		}

		return globalEndpoints;
	}
}