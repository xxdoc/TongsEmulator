VERSION 1.0 CLASS
BEGIN
  MultiUse = -1  'True
  Persistable = 0  'NotPersistable
  DataBindingBehavior = 0  'vbNone
  DataSourceBehavior  = 0  'vbNone
  MTSTransactionMode  = 0  'NotAnMTSObject
END
Attribute VB_Name = "Session"
Attribute VB_GlobalNameSpace = False
Attribute VB_Creatable = True
Attribute VB_PredeclaredId = False
Attribute VB_Exposed = False
Public WithEvents socket As Winsock
Attribute socket.VB_VarHelpID = -1

Public Key As String

Public ID As String
Public PW As String
Public IsLogin As Boolean
Public Nick As String

Public Character As Long

Public UserState As Long
Public UserLevel As Long
Public UserBlockDate As String

Private Sub Class_Initialize()
    Set socket = New Winsock
End Sub

Private Sub socket_Close()
    Log "<< ���� ���� / IP: " & socket.RemoteHostIP & " >>"
End Sub

Private Sub socket_DataArrival(ByVal bytesTotal As Long)
    Dim p As Packet
    Set p = New Packet

    Dim data() As Byte
    socket.GetData data, vbByte, bytesTotal
    p.SetPacketData data
    
    Dim OpCode As Long, DataLen As Long, Unknown As Long
    OpCode = p.ReadShort()
    DataLen = p.ReadShort()
    Unknown = p.ReadInt()
    
    Select Case OpCode
    Case 20001: ' �α��� ��û
        OnLoginReq p
    Case 20021: ' ĳ���� ���� �Ϸ�
        OnSelectCharacter p
    Case 30002: ' ä��
        OnChat p
    Case 50007: ' �� �����
        OnCreateRoom p
    Case Else:
        Log "<< ������ ��Ŷ ���� / OpCode: " & OpCode & " >>"
        Open AP() & "PacketDump\" & CStr(OpCode) & ".txt" For Append As #1
        Print #1, HexToStr(data)
        Print #1, StrConv(data, vbUnicode)
        Print #1, ""
        Close #1
    End Select
End Sub

Private Sub socket_Error(ByVal Number As Integer, Description As String, ByVal Scode As Long, ByVal Source As String, ByVal HelpFile As String, ByVal HelpContext As Long, CancelDisplay As Boolean)
    Log "<< ���� ���� / IP: " & socket.RemoteHostIP & " >>"
End Sub

Private Sub OnLoginReq(p As Packet)
    Dim TempID As String, TempPW As String
    TempID = p.ReadString(24)
    TempPW = p.ReadString(24)
    
    ' �ι��� ����
    TempID = RemoveNullStr(TempID)
    TempPW = RemoveNullStr(TempPW)
    
    Dim UD1 As Long
    UD1 = p.ReadInt()
    
    Dim TempSex As Long
    TempSex = p.ReadInt()
    
    Log "<< �α��� ��û >>" & vbCrLf & _
        "----------" & vbCrLf & _
        "��û Ŭ���̾�Ʈ: " & Key & vbCrLf & _
        "���̵�: " & TempID & vbCrLf & _
        "��й�ȣ: " & TempPW & vbCrLf & _
        "UnknownData1: " & UD1 & vbCrLf & _
        "����: " & TempSex & vbCrLf & _
        "----------"

    ' �α��� Ȯ���ϱ�
    Dim UserPW As String
    UserPW = ReadINI("info", "PW", AP & "Users\" & TempID & ".txt", "")

    UserState = ReadINI("info", "State", AP & "Users\" & TempID & ".txt", "")
    UserLevel = Val(ReadINI("info", "Level", AP & "Users\" & TempID & ".txt", "0"))
    UserBlockDate = ReadINI("info", "BlockDate", AP & "Users\" & TempID & ".txt", "")
    Nick = ReadINI("info", "Nick", AP & "Users\" & TempID & ".txt", "")
    
    ' �α��� ���
    ' PTCL 20002 : 1 = ����
    ' 2 = �뽺�뽺 ���� �α��� ����
    ' 3 = �̹� �α��ε� ���̵�
    ' 4 = �뽺�뽺 ���̵� ��й�ȣ ��ġ���� ����
    ' 5 = ���º�Ÿ ���� �Ⱓ �ƴ�
    ' 6 = ��ϵ� ��Ÿ�׽��Ͱ� �ƴ�
    ' 7 = Ŭ���̾�Ʈ ������ ��ġ���� ����
    ' 8 = �弳 �� �����м��� 1�����
    ' 9 = �弳 �� �����м��� XX���� �������� (�޽����� ����)
    ' ��Ÿ = �α��� ����
    ' PTCL 20023 : 1 = ����
    ' 2 = ���� �Է¿� ����
    ' 3 ���� = ������ �ߺ���
    
    Dim LoginResult As Long
    LoginResult = 1
    If Val(UserState) = 2 Then LoginResult = 8
    If Val(UserState) = 3 Then LoginResult = 9
    If StrComp(TempPW, UserPW, vbBinaryCompare) <> 0 Then LoginResult = 4
    If StrComp("", UserPW, vbBinaryCompare) = 0 Then LoginResult = 4
    
    ' �α��ο� �����ߴٸ� �α����ߴٴ� ����� ������
    If LoginResult = 1 Then
        ID = TempID
        PW = TempPW
        IsLogin = True
    End If
    
    ' ��Ŷ �����
    Dim op As Packet
    Set op = New Packet
    
    op.InitSendPacket 20002
    op.WriteInt LoginResult
    op.WriteInt 0
    op.WriteInt 0
    op.WriteInt UserLevel
    op.WriteInt 0
    op.WriteInt 0
    op.WriteString UserBlockDate
    
    socket.SendData op.GetPacketData
    DoEvents
End Sub

Private Sub OnSelectCharacter(p As Packet)
    Dim TempID As String
    TempID = p.ReadString(24)
    TempID = RemoveNullStr(TempID)
    
    Dim TempCharacter As Long
    TempCharacter = p.ReadInt()
    
    Log "<< ĳ���� ���� >>" & vbCrLf & _
        "----------" & vbCrLf & _
        "��û Ŭ���̾�Ʈ: " & Key & vbCrLf & _
        "���̵�: " & TempID & vbCrLf & _
        "ĳ����: " & TempCharacter & vbCrLf & _
        "----------"

    ' �� ��Ŷ�� ��������� �����ΰ�?
    If TempID <> ID Or IsLogin = False Then
        Log "�α��� ���� ���� Ŭ���̾�Ʈ�� ��û�� OnSelectCharacter()"
        Exit Sub
    End If
    
    ' ĳ���� ����
    Character = TempCharacter
    
    ' �г����� �ִ� 12����Ʈ
    Dim TempNick() As Byte
    TempNick = StrConv(Nick, vbFromUnicode)
    ReDim Preserve TempNick(11)
    
    ' ��Ŷ �����
    Dim op As Packet
    Set op = New Packet
    
    op.InitSendPacket 50002
    op.WriteShort 1
    op.WriteShort Character
    op.WriteShort 1
    op.WriteShort UserLevel
    op.WriteShort 0
    op.WriteShort 0
    op.WriteBytes TempNick
    op.WriteByte 71
    op.WriteByte 71
    op.WriteInt 0
    op.WriteInt 0
    op.WriteInt 0
    op.WriteInt 0
    op.WriteInt 0
    op.WriteInt 0
    op.WriteInt 0
    op.WriteInt 0
    op.WriteInt 0
    
    socket.SendData op.GetPacketData
    DoEvents
End Sub

Private Sub OnChat(p As Packet)
    ' 32 75 B0 00 CA 7A 00 00 CC CC CC CC CC CC CC CC 01 00 00 00 01 00 00 00 61 62 63 64 65 66 67 00 CC CC CC CC CC CC CC CC CC CC CC CC CC CC CC CC CC CC CC CC CC CC CC CC CC CC CC CC CC CC CC CC CC CC CC CC CC CC CC CC CC CC CC CC CC CC CC CC CC CC CC CC CC CC CC CC CC CC CC CC CC CC CC CC CC CC CC CC CC CC CC CC CC CC CC CC CC CC CC CC CC CC CC CC CC CC CC CC CC CC CC CC CC CC CC CC CC CC CC CC CC CC CC CC CC CC CC CC CC CC CC CC CC CC CC CC CC CC CC CC 47 4D 5F BC AE 00 CC CC CC CC CC CC CC CC CC CC CC CC CC CC CC CC CC CC

    Dim UD1 As Long, UD2 As Long
    UD1 = p.ReadInt()
    UD2 = p.ReadInt()
    
    Dim UD3 As Long, UD4 As Long
    UD3 = p.ReadInt() ' 1
    UD4 = p.ReadInt() ' 1
    
    Dim TempChat As String, rChat As String
    TempChat = p.ReadString(128)
    TempChat = RemoveNullStr(TempChat)
    
    Dim TempNick As String, rNick As String
    TempNick = p.ReadString(24)
    TempNick = RemoveNullStr(TempNick)
    
    Log "<< ä�� >>" & vbCrLf & _
        "----------" & vbCrLf & _
        "��û Ŭ���̾�Ʈ: " & Key & vbCrLf & _
        "UD3, UD4: " & UD3 & ", " & UD4 & vbCrLf & _
        "�г���: " & TempNick & vbCrLf & _
        "����: " & TempChat & vbCrLf & _
        "----------"

    ' �� ��Ŷ�� ��������� �����ΰ�?
    If TempNick <> Nick Or IsLogin = False Then
        Log "�α��� ���� ���� Ŭ���̾�Ʈ�� ��û�� OnChat()"
        Exit Sub
    End If
    
    ' ��Ŷ �����
    Dim op As Packet
    Set op = New Packet
    
    op.InitSendPacket 30002
    op.WriteInt 0
    op.WriteInt 0
    op.WriteInt UD3
    op.WriteInt UD4
    op.WriteString TempChat
    op.WriteString TempNick

    socket.SendData p.GetPacketData
    DoEvents
End Sub

Private Sub OnCreateRoom(p As Packet)
    ' 32 75 B0 00 CA 7A 00 00 CC CC CC CC CC CC CC CC 01 00 00 00 01 00 00 00 61 62 63 64 65 66 67 00 CC CC CC CC CC CC CC CC CC CC CC CC CC CC CC CC CC CC CC CC CC CC CC CC CC CC CC CC CC CC CC CC CC CC CC CC CC CC CC CC CC CC CC CC CC CC CC CC CC CC CC CC CC CC CC CC CC CC CC CC CC CC CC CC CC CC CC CC CC CC CC CC CC CC CC CC CC CC CC CC CC CC CC CC CC CC CC CC CC CC CC CC CC CC CC CC CC CC CC CC CC CC CC CC CC CC CC CC CC CC CC CC CC CC CC CC CC CC CC CC 47 4D 5F BC AE 00 CC CC CC CC CC CC CC CC CC CC CC CC CC CC CC CC CC CC

    Dim TempRoomName As String
    TempRoomName = p.ReadString(24)
    TempID = RemoveNullStr(TempRoomName)
    
    Dim TempRoomPass As String
    TempRoomPass = p.ReadString(12)
    TempRoomPass = RemoveNullStr(TempRoomPass)
    
    Dim MaxUser As Long
    MaxUser = p.ReadInt()
    
    Dim UD1 As Long
    UD1 = p.ReadInt()
    
    Dim NoItem As Long
    NoItem = p.ReadInt()
    
    Log "<< �� ����� >>" & vbCrLf & _
        "----------" & vbCrLf & _
        "��û Ŭ���̾�Ʈ: " & Key & vbCrLf & _
        "�� �̸�: " & TempRoomName & vbCrLf & _
        "�� ��й�ȣ: " & TempRoomPass & vbCrLf & _
        "�ο���: " & MaxUser & vbCrLf & _
        "������: " & NoItem & vbCrLf & _
        "----------"

    ' �� ��Ŷ�� ��������� �����ΰ�?
    If IsLogin = False Then
        Log "�α��� ���� ���� Ŭ���̾�Ʈ�� ��û�� OnChat()"
        Exit Sub
    End If
    
    ' ��Ŷ �����
    Dim op As Packet
    Set op = New Packet
    
    op.InitSendPacket 50008
    op.WriteInt 0
    op.WriteInt 0
    op.WriteInt 0
    op.WriteInt 0

    socket.SendData op.GetPacketData
    DoEvents
End Sub

