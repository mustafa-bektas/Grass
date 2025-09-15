using UnityEngine;
using UnityEngine.Rendering;

public class ComputeGrassManager : MonoBehaviour
{
    [Header("Grass Settings")]
    public GameObject grassPrefab;
    public ComputeShader grassComputeShader;
    public Material grassMaterial;
    public GameObject terrain;
    public Vector2 areaSize = new Vector2(50, 50);
    public int grassCount = 10000;
    public float randomSeed = 1.0f;
    
    [Header("Height Variation")]
    public float heightVariationFrequency = 0.2f;
    public float minHeightScale = 0.5f;
    public float maxHeightScale = 1.5f;
    
    [Header("Wind Settings")]
    public Vector2 windDirection = new Vector2(1, 0);
    public float windStrength = 0.5f;
    public float windSpeed = 1.0f;
    [Range(0, 2)]
    public float windScaleInfluence = 1.0f;
    
    [Header("Runtime")]
    public bool regenerateOnStart = true;
    
    private ComputeBuffer grassBuffer;
    private ComputeBuffer argsBuffer;
    private Mesh grassMesh;
    private uint[] args = new uint[5] { 0, 0, 0, 0, 0 };
    
    [System.Serializable]
    public struct GrassData
    {
        public Vector3 position;
        public float rotation;
        public float scale;
        public float yellowness;
    }
    
    void Start()
    {
        if (regenerateOnStart)
        {
            GenerateGrass();
        }
    }
    
    public void GenerateGrass()
    {
        ClearGrass();
        
        if (grassMaterial != null)
        {
            if (grassMaterial.shader.name != "Custom/GrassBillboard")
            {
                return;
            }
        }
        
        // Get mesh from grass prefab
        if (grassPrefab != null)
        {
            MeshFilter meshFilter = grassPrefab.GetComponent<MeshFilter>();
            if (meshFilter != null)
            {
                grassMesh = meshFilter.sharedMesh;
            }
        }
        
        grassBuffer = new ComputeBuffer(grassCount, sizeof(float) * 6); // 3 for pos, 1 rot, 1 scale, 1 yellowness
        
        grassComputeShader.SetBuffer(0, "grassBuffer", grassBuffer);
        grassComputeShader.SetVector("areaSize", areaSize);
        grassComputeShader.SetInt("grassCount", grassCount);
        grassComputeShader.SetFloat("seed", randomSeed);
        grassComputeShader.SetFloat("heightVariationFrequency", heightVariationFrequency);
        grassComputeShader.SetFloat("minHeightScale", minHeightScale);
        grassComputeShader.SetFloat("maxHeightScale", maxHeightScale);

        if (terrain != null)
        {
            Renderer terrainRenderer = terrain.GetComponent<Renderer>();
            if (terrainRenderer != null)
            {
                Material terrainMaterial = terrainRenderer.sharedMaterial;
                if (terrainMaterial.HasProperty("_HeightMap") && terrainMaterial.HasProperty("_DisplacementStrength"))
                {
                    grassComputeShader.SetTexture(0, "_HeightMap", terrainMaterial.GetTexture("_HeightMap"));
                    grassComputeShader.SetFloat("_DisplacementStrength", terrainMaterial.GetFloat("_DisplacementStrength"));
                    grassComputeShader.SetVector("_TerrainPosition", terrain.transform.position);
                    grassComputeShader.SetVector("_TerrainSize", terrain.GetComponent<MeshFilter>().sharedMesh.bounds.size * terrain.transform.localScale.x);
                }
            }
        }
        
        int totalThreadsNeeded = Mathf.CeilToInt(grassCount / 64.0f) * 64;
        int threadsPerRow = 65536; // Max threads per dimension
        int threadGroupsX = Mathf.CeilToInt(Mathf.Min(totalThreadsNeeded, threadsPerRow) / 8.0f);
        int threadGroupsY = Mathf.CeilToInt(totalThreadsNeeded / (float)(threadGroupsX * 8) / 8.0f);
        
        threadGroupsX = Mathf.Min(threadGroupsX, 65535);
        threadGroupsY = Mathf.Min(threadGroupsY, 65535);
        
        grassComputeShader.Dispatch(0, threadGroupsX, threadGroupsY, 1);
        
        SetupIndirectArgs();
    }
    
    void SetupIndirectArgs()
    {
        if (grassMesh != null)
        {
            args[0] = (uint)grassMesh.GetIndexCount(0);
            args[1] = (uint)grassCount;
            args[2] = (uint)grassMesh.GetIndexStart(0);
            args[3] = (uint)grassMesh.GetBaseVertex(0);
        }
        
        argsBuffer = new ComputeBuffer(1, args.Length * sizeof(uint), ComputeBufferType.IndirectArguments);
        argsBuffer.SetData(args);
    }
    
    void Update()
    {
        if (grassMesh != null && grassMaterial != null && grassBuffer != null && argsBuffer != null)
        {
            grassMaterial.SetBuffer("_GrassBuffer", grassBuffer);
            grassMaterial.SetVector("_ManagerPosition", transform.position);
            
            grassMaterial.SetVector("_WindDirection", windDirection.normalized);
            grassMaterial.SetFloat("_WindStrength", windStrength);
            grassMaterial.SetFloat("_WindSpeed", windSpeed);
            grassMaterial.SetFloat("_WindScaleInfluence", windScaleInfluence);
            
            Graphics.DrawMeshInstancedIndirect(grassMesh, 0, grassMaterial, new Bounds(transform.position, Vector3.one * 1000), argsBuffer);
        }
    }
    
    public void ClearGrass()
    {
        if (grassBuffer != null)
        {
            grassBuffer.Release();
            grassBuffer = null;
        }
        
        if (argsBuffer != null)
        {
            argsBuffer.Release();
            argsBuffer = null;
        }
    }
    
    void OnDestroy()
    {
        ClearGrass();
    }
    
    void OnDrawGizmosSelected()
    {
        Gizmos.color = Color.green;
        Gizmos.DrawWireCube(transform.position, new Vector3(areaSize.x, 0.1f, areaSize.y));
    }
}
