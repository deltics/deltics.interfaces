
{$i deltics.interfacedobjects.inc}

  unit Deltics.InterfacedObjects.InterfacedObjectList;


interface

  uses
    Contnrs,
    Deltics.InterfacedObjects.InterfacedObject,
    Deltics.InterfacedObjects.Interfaces.IInterfacedObjectList;


  type
    TInterfacedObjectList = class(TInterfacedObject)//, IInterfacedObjectList)
    private
      fItems: TObjectList;
      procedure OnItemDestroyed(aSender: TObject);
    public
      constructor Create;
      destructor Destroy; override;

    // IInterfacedObjectList
    protected
      function get_Count: Integer;
      function get_Item(const aIndex: Integer): IUnknown;
      function get_Object(const aIndex: Integer): TObject;
    public
      function Add(const aInterface: IInterface): Integer; overload;
      function Add(const aObject: TObject): Integer; overload;
      procedure Delete(const aIndex: Integer);
      function IndexOf(const aObject: TObject): Integer; overload;
      property Count: Integer read get_Count;
      property Items[const aIndex: Integer]: IUnknown read get_Item; default;
      property Objects[const aIndex: Integer]: TObject read get_Object;
    end;



implementation

  uses
    Classes,
    SysUtils,
    Deltics.Multicast,
    Deltics.InterfacedObjects;



{ TInterfacedObjectList -------------------------------------------------------------------------- }

  type
    TListItem = class
      ItemObject: TObject;
      ItemInterface: IUnknown;
    end;


  { - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - }
  constructor TInterfacedObjectList.Create;
  begin
    inherited Create;

    fItems := TObjectList.Create(TRUE);
  end;


  { - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - }
  destructor TInterfacedObjectList.Destroy;
  begin
    FreeAndNIL(fItems);

    inherited;
  end;


  { - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - }
  procedure TInterfacedObjectList.OnItemDestroyed(aSender: TObject);
  var
    idx: Integer;
  begin
    idx := IndexOf(aSender);
    if idx = -1 then
      EXIT;

    Delete(idx);
  end;


  { - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - }
  function TInterfacedObjectList.Add(const aInterface: IInterface): Integer;
  var
    i: IInterfacedObject;
  begin
    if NOT Supports(aInterface, IInterfacedObject, i) then
      raise EInvalidOperation.CreateFmt('Items added to a %s must implement IInterfacedObject', [ClassName]);

    result := Add(i.AsObject);
  end;


  { - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - }
  function TInterfacedObjectList.Add(const aObject: TObject): Integer;
  var
    item: TListItem;
    intf: IInterfacedObject;
    onDestroy: IOn_Destroy;
  begin
    if (ReferenceCount = 0) then
      raise EInvalidOperation.Create('You appear to be using a reference counted object list via an object reference.  Reference counted lists MUST be used via an interface reference to avoid errors arising from the internal On_Destroy mechanism');

    item := TListItem.Create;
    item.ItemObject := aObject;

    if Assigned(aObject) then
    begin
      aObject.GetInterface(IUnknown, item.ItemInterface);

      // If the object being added is reference counted then its presence in this
      //  list ensures it will not be freed unless and until it is removed.
      //
      // But if the object is NOT reference counted then it could be destroyed
      //  while in this list; we need to subscribe to its On_Destroy event so
      //  that we can remove the item from the list if it is destroyed.
      //
      // NOTE: Subscribing to the On_Destroy of a reference counted object
      //        establishes a mutual dependency between the list and the object
      //        which causes a death-embrace when the list is destroyed.
      //
      //   i.e. Do NOT subscribe to reference counted object On_Destroy events!

      if Supports(aObject, IInterfacedObject, intf)
       and intf.IsReferenceCounted
       and Supports(aObject, IOn_Destroy, onDestroy) then
        onDestroy.Add(OnItemDestroyed);
    end;

    result := fItems.Add(item);
  end;


  { - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - }
  procedure TInterfacedObjectList.Delete(const aIndex: Integer);
  begin
    fItems.Delete(aIndex);
  end;


  { - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - }
  function TInterfacedObjectList.get_Count: Integer;
  begin
    result := fItems.Count;
  end;


  { - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - }
  function TInterfacedObjectList.get_Item(const aIndex: Integer): IUnknown;
  begin
    result := TListItem(fItems[aIndex]).ItemInterface;
  end;


  { - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - }
  function TInterfacedObjectList.get_Object(const aIndex: Integer): TObject;
  begin
    result := TListItem(fItems[aIndex]).ItemObject;
  end;


  { - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - }
  function TInterfacedObjectList.IndexOf(const aObject: TObject): Integer;
  begin
    for result := 0 to Pred(fItems.Count) do
      if TListItem(fItems[result]).ItemObject = aObject then
        EXIT;

    result := -1;
  end;



end.
