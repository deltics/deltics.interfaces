
{$i deltics.inc}

  unit Test.InterfacedObjectList;


interface

  uses
    Deltics.Smoketest;


  type
    TInterfacedObjectListTests = class(TTest)
      procedure InterfacedObjectAddedToListIsRemovedWhenDestroyed;
      procedure AddingItemsViaObjectReferenceIsAnInvalidOperation;
      procedure AddingItemsViaInterfaceReferenceIsSuccessful;
    end;


implementation

  uses
    Deltics.Exceptions,
    Deltics.InterfacedObjects;



  type
    TInterfacedObjectListSubClassExposingAddMethod = class(TInterfacedObjectList);



{ TTestInterfacedObjectList }

  procedure TInterfacedObjectListTests.AddingItemsViaInterfaceReferenceIsSuccessful;
  var
    sut: IInterfacedObjectList;
    io: TInterfacedObject;
  begin
    sut := TInterfacedObjectList.Create;

    io := TInterfacedObject.Create;
    try
      sut.Add(io);

      Test('Count').Assert(sut.Count).Equals(1);

    finally
      io.Free;
    end;
  end;


  procedure TInterfacedObjectListTests.AddingItemsViaObjectReferenceIsAnInvalidOperation;
  var
    sut: TInterfacedObjectListSubClassExposingAddMethod;
    io: TInterfacedObject;
  begin
    Test.RaisesException(EInvalidOperation);

    sut := TInterfacedObjectListSubClassExposingAddMethod.Create;
    try
      io := TInterfacedObject.Create;
      try
        sut.Add(io);

      finally
        io.Free;
      end;

    finally
      sut.Free;
    end;
  end;


  procedure TInterfacedObjectListTests.InterfacedObjectAddedToListIsRemovedWhenDestroyed;
  var
    sut: IInterfacedObjectList;
    io: TInterfacedObject;
  begin
    sut := TInterfacedObjectList.Create;
    io := TInterfacedObject.Create;

    Test('Count').Assert(sut.Count).Equals(0);

    sut.Add(io);

    Test('Count').Assert(sut.Count).Equals(1);

    io.Free;

    Test('Count').Assert(sut.Count).Equals(0);
  end;


end.
