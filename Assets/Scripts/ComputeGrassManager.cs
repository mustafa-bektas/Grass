using UnityEngine;

public class ComputeGrassManager : MonoBehaviour
{
    [Header("Grass Settings")]
    public GameObject grassPrefab;
    public ComputeShader grassComputeShader;
    public Vector2 areaSize = new Vector2(50, 50);
    public int grassCount = 10000;
    public float randomSeed = 1.0f;
    
    [Header("Runtime")]
    public bool regenerateOnStart = true;
    
    private ComputeBuffer grassBuffer;
    private GrassData[] grassDataArray;
    private GameObject[] grassInstances;
    
    [System.Serializable]
    public struct GrassData
    {
        public Vector3 position;
        public float rotation;
        public float scale;
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
        
        grassBuffer = new ComputeBuffer(grassCount, sizeof(float) * 5); // 3 for pos, 1 scale, 1 rot
        grassDataArray = new GrassData[grassCount];
        
        grassComputeShader.SetBuffer(0, "grassBuffer", grassBuffer);
        grassComputeShader.SetVector("areaSize", areaSize);
        grassComputeShader.SetInt("grassCount", grassCount);
        grassComputeShader.SetFloat("seed", randomSeed);
        
        int threadGroups = Mathf.CeilToInt(grassCount / 64.0f);
        grassComputeShader.Dispatch(0, threadGroups, 1, 1);
        
        grassBuffer.GetData(grassDataArray);
        
        CreateGrassInstances();
        
        grassBuffer.Release();
    }
    
    void CreateGrassInstances()
    {
        grassInstances = new GameObject[grassCount];
        
        for (int i = 0; i < grassCount; i++)
        {
            GrassData data = grassDataArray[i];
            
            GameObject grass = Instantiate(grassPrefab, transform);
            grass.transform.position = transform.position + data.position;
            grass.transform.rotation = Quaternion.Euler(0, data.rotation * Mathf.Rad2Deg, 0);
            grass.transform.localScale = Vector3.one * data.scale * 0.5f;
            
            grassInstances[i] = grass;
        }
    }
    
    public void ClearGrass()
    {
        if (grassInstances != null)
        {
            for (int i = 0; i < grassInstances.Length; i++)
            {
                if (grassInstances[i] != null)
                {
                    DestroyImmediate(grassInstances[i]);
                }
            }
            grassInstances = null;
        }
        
        if (grassBuffer != null)
        {
            grassBuffer.Release();
            grassBuffer = null;
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