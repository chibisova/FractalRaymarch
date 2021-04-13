using UnityEngine;
using System.Collections;

public class FractalTerrain : MonoBehaviour {

	public string seed;
	[Range(0.1f, 1f)]
	public float roughness = 0.5f;

	System.Random rng;
	float[,] heightmap;
	TerrainData td;
	int hash;
	int size;
	int max;

	void Awake(){
		td = GetComponent<Terrain> ().terrainData;
		size = td.heightmapResolution;
		max = size - 1;
	}

	void Start(){
		heightmap = new float[size,size];
		for (int x = 0; x < size; x++) {
			for (int y = 0; y < size; y++) {
				heightmap[x,y] = 0.5f;
			}
		}
		GenerateTerrain ();
	}

	void GenerateTerrain(){
		if (seed != "") {
			hash = seed.GetHashCode ();
			rng = new System.Random (hash);
		} else {
			rng = new System.Random();
		}
		Divide (max);
		td.SetHeights (0, 0, heightmap);
	}

	void Divide(int size){
		int half = size / 2;
		if (half < 1) {
			return;
		}
		for (int y = half; y < max; y += size) {
			for (int x = half; x < max; x += size) {
				Square(x, y, half, ((float)rng.NextDouble() - 0.5f)/(max/size));
			}
		}
		for (int y = 0; y <= max; y += half) {
			for (int x = (y + half) % size; x <= max; x += size) {
				Diamond(x, y, half, ((float)rng.NextDouble() - 0.5f)/(max/size));
			}
		}
		Divide(half);
	}

	void Diamond(int x, int y, int size, float offset){
		float ave = Average(new float[4]{
			Get(x, y - size),
			Get(x + size, y),
			Get(x, y + size),
			Get(x - size, y)});
		
		heightmap[x, y] = ave + offset * roughness;
	}

	void Square(int x, int y, int size, float offset){
		float ave = Average(new float[4]{
		Get (x - size, y - size),
		Get (x + size, y - size),
		Get (x + size, y + size),
		Get (x - size, y + size)});

		heightmap[x, y] = ave + offset * roughness;
	}

	void OnGUI(){
		if (GUI.Button (new Rect (0, 0, 120, 40), "Generate Terrain")) {
			GenerateTerrain();
		}
	}

	float Get(int x, int y){
		if (x < 0 || x > max || y < 0 || y > max) {
			return 0;
		}
		return heightmap[x, y];
	}

	float Average(float[] values){
		float total = 0;
		foreach (float f in values) {
			total += f;
		}
		return total / values.Length;
	}
}