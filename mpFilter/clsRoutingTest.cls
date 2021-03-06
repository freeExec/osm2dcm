VERSION 1.0 CLASS
BEGIN
  MultiUse = -1  'True
  Persistable = 0  'NotPersistable
  DataBindingBehavior = 0  'vbNone
  DataSourceBehavior  = 0  'vbNone
  MTSTransactionMode  = 0  'NotAnMTSObject
END
Attribute VB_Name = "clsRoutingTest"
Attribute VB_GlobalNameSpace = False
Attribute VB_Creatable = False
Attribute VB_PredeclaredId = False
Attribute VB_Exposed = False
'***************************************************************************
'���� ��������� ����������� �����
'***************************************************************************
Option Explicit

'��������� ����� � �����������
'��������
Const RS_SUBGRAPH_ID = "Id"
Const RS_SUBGRAPH_ROADCOUNT = "RoadCount"
Const RS_SUBGRAPH_LAT1 = "Lat1"
Const RS_SUBGRAPH_LON1 = "Lon1"
Const RS_SUBGRAPH_LAT2 = "Lat2"
Const RS_SUBGRAPH_LON2 = "Lon2"
Const RS_SUBGRAPH_HAS_EXTNODES = "HasExternalNodes"

'�������
Const RS_NODE_ID = "Id"
Const RS_NODE_SUBGRAPH = "SubGraphID"

'���������� � �������
Dim rsSubGraph     As ADODB.Recordset
Dim rsNodes        As ADODB.Recordset
Dim intSubgraphCount As Long

Private NTotalRoads As Long
Private NRoutiningEdges As Long

Private Sub Class_Initialize()

 On Error GoTo finalize
  
  '��������
  Set rsSubGraph = New ADODB.Recordset
  rsSubGraph.Fields.Append RS_SUBGRAPH_ID, adInteger
  rsSubGraph.Fields.Append RS_SUBGRAPH_ROADCOUNT, adInteger
  rsSubGraph.Fields.Append RS_SUBGRAPH_LAT1, adDouble
  rsSubGraph.Fields.Append RS_SUBGRAPH_LON1, adDouble
  rsSubGraph.Fields.Append RS_SUBGRAPH_LAT2, adDouble
  rsSubGraph.Fields.Append RS_SUBGRAPH_LON2, adDouble
  rsSubGraph.Fields.Append RS_SUBGRAPH_HAS_EXTNODES, adBoolean
  
    
  rsSubGraph.Open
  rsSubGraph(RS_SUBGRAPH_ID).Properties("Optimize") = True
  
  '�������
  Set rsNodes = New ADODB.Recordset
  rsNodes.Fields.Append RS_NODE_ID, adInteger
  rsNodes.Fields.Append RS_NODE_SUBGRAPH, adInteger
  rsNodes.Open
  rsNodes(RS_NODE_ID).Properties("Optimize") = True
  rsNodes(RS_NODE_SUBGRAPH).Properties("Optimize") = True
  
  
  '��������� �������� �������� ���������
  intSubgraphCount = 0
  NTotalRoads = 0
  NRoutiningEdges = 0
  
finalize:
  If Err.Number <> 0 Then
    Err.Raise Err.Number, "Class_Initialize", Err.Description & " clsAddrRegistry.Initialize:" & Erl
  End If
End Sub

Private Sub Class_Terminate()
  Set rsSubGraph = Nothing
  Set rsNodes = Nothing
End Sub

'����� ������ �������.
'����������� ������.
'���������� ID ������ � ������ ������� �� ������.
'� ��� ������ �� BBOX
'
'�������� ����� ��� �������.
'1. ������ � ������� ������ ���������.
'2. ����� ��������� ������ �� ������
'3. ���������, ���� �� ������� (��������), � ������� ��� ������  ���������� ���� ������� �����.
'* ���� ���, �������� � ������ ����� �������, ������ � �� ���� �������� ��� �����������
'  � ������� ��������.
'* ���� ���� ����� ���� ����� �������, ������ � �� ���� �������� ��� ����������� � ������� ��������.
'* ���� ����� ��������� ��������� (������ ������ ������ � ��������� �� ��� ��������� ���������,
'  ������, ����� �������, ���������� ����)
'- �������� ������ ������ �������, ��������� ��������� �� ������, ����������� � ��� ����
'  � ������ �������� ��� ����������� � ������� ��������
'4. ���������� � ������ 2, ���� ���� �������������� �����.
'5. ���������� ������ ��������� ���������, � ������� ��������(��� �����������) ����� �����.
'� ������ ������ ���� ���� �������. ����������� ����� ���� ��������� (�����-������ ����� ��������).
' � ����� ������ �������� � ����������� (�� �������) ������� ���� ������.
'
' NodeList() - ������ ���������� ���������� ������
' NodeExtrAttrList() - 0 ��� ������� ������� � 1 ��� ������� (������� ����������� � ���-�� �� ��������� �����)
' �������, ���������� ������� �������, �� �������� ������ �������������.
Public Sub AddRoad(NodeList() As Long, NodeExtrAttrList() As Long, _
                   lat1 As Double, lon1 As Double, lat2 As Double, lon2 As Double)
Dim i As Integer
Dim N As Long ' ����� ��������� ���������
Dim SubGraphs(10000) As Long '  ��������� �������� (1..N)
Dim blnHasExternalNodes As Boolean

  N = 0
  blnHasExternalNodes = False
  For i = LBound(NodeList) To UBound(NodeList)
    rsNodes.Filter = RS_NODE_ID & "=" & NodeList(i)
    If rsNodes.RecordCount > 1 Then
      Err.Raise vbObjectError, "AddRoad", "Error on the previous step, Node belongs to more than one sub-graph"
    End If
    If rsNodes.RecordCount > 0 Then
      '������� ������
      N = N + 1
      SubGraphs(N) = rsNodes(RS_NODE_SUBGRAPH).Value
    End If
    
    If NodeExtrAttrList(i) = 1 Then
      blnHasExternalNodes = True
    End If
  Next i
  
  If N = 0 Then
    ' ������� ����� �������
    rsSubGraph.AddNew
    rsSubGraph(RS_SUBGRAPH_ID).Value = intSubgraphCount 'rsSubGraph.RecordCount
    intSubgraphCount = intSubgraphCount + 1
    rsSubGraph(RS_SUBGRAPH_ROADCOUNT).Value = 0
    rsSubGraph(RS_SUBGRAPH_LAT1).Value = lat1
    rsSubGraph(RS_SUBGRAPH_LON1).Value = lon1
    rsSubGraph(RS_SUBGRAPH_LAT2).Value = lat2
    rsSubGraph(RS_SUBGRAPH_LON2).Value = lon2
    rsSubGraph(RS_SUBGRAPH_HAS_EXTNODES).Value = blnHasExternalNodes
        
    N = 1
    SubGraphs(1) = rsSubGraph(RS_SUBGRAPH_ID).Value
  End If
  
  '��������� ��������� ��������
  For i = 2 To N
    If SubGraphs(1) <> SubGraphs(i) Then
      MergeSubGraphs SubGraphs(1), SubGraphs(i)
    End If
  Next i
  
  '������� ������� ����� ������ � ������ �������
  For i = LBound(NodeList) To UBound(NodeList)
    AddNodeToSubGraph SubGraphs(1), NodeList(i)
  Next i
  
  '������� ������ � ��� ������ �������.
  '* ����� ����� ������������ �� �������
  '* Bbox �����������
  
  rsSubGraph.Filter = RS_SUBGRAPH_ID & "=" & SubGraphs(1)
  rsSubGraph(RS_SUBGRAPH_ROADCOUNT).Value = rsSubGraph(RS_SUBGRAPH_ROADCOUNT).Value + 1
  If lat1 < rsSubGraph(RS_SUBGRAPH_LAT1).Value Then rsSubGraph(RS_SUBGRAPH_LAT1).Value = lat1
  If lon1 < rsSubGraph(RS_SUBGRAPH_LON1).Value Then rsSubGraph(RS_SUBGRAPH_LON1).Value = lon1
  If lat2 > rsSubGraph(RS_SUBGRAPH_LAT2).Value Then rsSubGraph(RS_SUBGRAPH_LAT2).Value = lat2
  If lon2 > rsSubGraph(RS_SUBGRAPH_LON2).Value Then rsSubGraph(RS_SUBGRAPH_LON2).Value = lon2
  
  '���� � ������ ������ ���� ������� ����, ������ �� ���� �������� ���� ������� ����.
  If blnHasExternalNodes Then rsSubGraph(RS_SUBGRAPH_HAS_EXTNODES).Value = True
  
  '����� ����� ����� ��� �� �������������.
  
  NTotalRoads = NTotalRoads + 1
  
  '����� ���������� ����� � ������ ������ ����� ���������� ���������� ������ ����� ����.
  NRoutiningEdges = NRoutiningEdges + (UBound(NodeList) - LBound(NodeList))

  
  rsSubGraph.Filter = adFilterNone
  
  
End Sub
'���� intGraph2ID �������������� � ����� intGraph1ID
Private Sub MergeSubGraphs(ByVal intGraph1ID As Long, ByVal intGraph2ID As Long)
Dim Nroads As Long
Dim lat1 As Double, lon1 As Double, lat2 As Double, lon2 As Double
Dim blnHasExternalNodes As Boolean
Dim varNodeFilter
Dim varSGFilter
  '����� ����� � ������ �������� �������������
  varSGFilter = rsSubGraph.Filter
  rsSubGraph.Filter = RS_SUBGRAPH_ID & "=" & intGraph2ID
  
  '���� ��� ���� ��� ������, ������ ��� ������ ��������� ��������� �� ����������
  If rsSubGraph.RecordCount <> 0 Then
    
    '����� ����� � bbox "������������" � ��������� ��������
    Nroads = rsSubGraph(RS_SUBGRAPH_ROADCOUNT).Value
    lat1 = rsSubGraph(RS_SUBGRAPH_LAT1).Value
    lon1 = rsSubGraph(RS_SUBGRAPH_LON1).Value
    lat2 = rsSubGraph(RS_SUBGRAPH_LAT2).Value
    lon2 = rsSubGraph(RS_SUBGRAPH_LON2).Value
    blnHasExternalNodes = rsSubGraph(RS_SUBGRAPH_HAS_EXTNODES).Value
    
    '������ ���������. ����� ����� ���������� �� ������ ������
    rsSubGraph(RS_SUBGRAPH_ROADCOUNT).Value = 0
    rsSubGraph.Delete adAffectCurrent
   
    rsSubGraph.Filter = adFilterNone
  
    rsSubGraph.Filter = RS_SUBGRAPH_ID & "=" & intGraph1ID
    rsSubGraph(RS_SUBGRAPH_ROADCOUNT).Value = rsSubGraph(RS_SUBGRAPH_ROADCOUNT).Value + Nroads
    
    '� ��� �� ���� �� BBox ���������
    If lat1 < rsSubGraph(RS_SUBGRAPH_LAT1).Value Then rsSubGraph(RS_SUBGRAPH_LAT1).Value = lat1
    If lon1 < rsSubGraph(RS_SUBGRAPH_LON1).Value Then rsSubGraph(RS_SUBGRAPH_LON1).Value = lon1
    If lat2 > rsSubGraph(RS_SUBGRAPH_LAT2).Value Then rsSubGraph(RS_SUBGRAPH_LAT2).Value = lat2
    If lon2 > rsSubGraph(RS_SUBGRAPH_LON2).Value Then rsSubGraph(RS_SUBGRAPH_LON2).Value = lon2
    
    '���� � ������ �������� ���� ������� ����, ������  � � ������������ �������� ���� ������� ����.
    If blnHasExternalNodes Then rsSubGraph(RS_SUBGRAPH_HAS_EXTNODES).Value = True
  
  End If
  
  rsSubGraph.Filter = varSGFilter
  '���� �������� ������������� ������ �������
  varNodeFilter = rsNodes.Filter
  rsNodes.Filter = RS_NODE_SUBGRAPH & "=" & intGraph2ID
  Do While Not rsNodes.EOF
    rsNodes(RS_NODE_SUBGRAPH).Value = intGraph1ID
    rsNodes.MoveNext
  Loop
  
  rsNodes.Filter = varNodeFilter
  
  'BBox'� ������������
End Sub

'��������� ���� � ����
Private Sub AddNodeToSubGraph(ByVal intGraphID As Long, ByVal intNodeID As Long)
Dim varNodeFilter
  varNodeFilter = rsNodes.Filter
  rsNodes.Filter = RS_NODE_ID & "=" & intNodeID
  If rsNodes.RecordCount = 0 Then
    rsNodes.AddNew
    rsNodes(RS_NODE_ID).Value = intNodeID
    rsNodes(RS_NODE_SUBGRAPH).Value = intGraphID
  Else
    If rsNodes(RS_NODE_SUBGRAPH).Value <> intGraphID Then
      Err.Raise vbObjectError, "AddNodeToSubGraph", "Internal Algorithm error: wrong sub-graph!"
    End If
  End If
  rsNodes.Filter = varNodeFilter

End Sub
'C��������� ������ ������ � xml
Public Function PrintRegistryToXML(FileNumber As Long) As String
  
  'rsSubGraph.Filter = adFilterNone
  '������� ������ ������� ��� "������� ���"
  rsSubGraph.Filter = RS_SUBGRAPH_HAS_EXTNODES & "=False"
  
  rsSubGraph.Sort = RS_SUBGRAPH_ROADCOUNT & " desc"
  
  Print #FileNumber, "<Summary>"
  Print #FileNumber, "  <NumberOfSubgraphs>" & rsSubGraph.RecordCount & "</NumberOfSubgraphs>"
  Print #FileNumber, "  <NumberOfRoads>" & NTotalRoads & "</NumberOfRoads>"
  Print #FileNumber, "  <NumberOfRoutingEdges>" & NRoutiningEdges & "</NumberOfRoutingEdges>"
  
  Print #FileNumber, "</Summary>"
  
  Print #FileNumber, "<SubgraphList>"
  Do While Not rsSubGraph.EOF
    Print #FileNumber, "  <Subgraph>"
    Print #FileNumber, "    <NumberOfRoads>" & rsSubGraph(RS_SUBGRAPH_ROADCOUNT).Value & "</NumberOfRoads>"
    Print #FileNumber, "    <Bbox>"
    Print #FileNumber, "      <Lat1>" & rsSubGraph(RS_SUBGRAPH_LAT1).Value & "</Lat1>"
    Print #FileNumber, "      <Lon1>" & rsSubGraph(RS_SUBGRAPH_LON1).Value & "</Lon1>"
    Print #FileNumber, "      <Lat2>" & rsSubGraph(RS_SUBGRAPH_LAT2).Value & "</Lat2>"
    Print #FileNumber, "      <Lon2>" & rsSubGraph(RS_SUBGRAPH_LON2).Value & "</Lon2>"
    Print #FileNumber, "    </Bbox>"
    Print #FileNumber, "  </Subgraph>"
    rsSubGraph.MoveNext
  Loop
  Print #FileNumber, "</SubgraphList>"
  
End Function


Private Function MakeXmlString(str As String) As String
  str = Replace(str, "&", "&amp;")
  MakeXmlString = str
End Function
Private Function StrForFilter(ByVal str As String) As String
   StrForFilter = Replace(str, "'", "''")
End Function
