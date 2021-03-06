// Generated by CoffeeScript 1.9.0
(function() {
  var Collection, Index, Key, MultiValuedIndex, PrimaryIndex, Store, UniqueIndex, capitalize, _,
    __extends = function(child, parent) { for (var key in parent) { if (__hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; },
    __hasProp = {}.hasOwnProperty,
    __slice = [].slice;

  if (typeof require !== 'undefined') {
    _ = require('lodash');
  } else {
    if (typeof this._ === 'undefined') {
      throw new Error('store requires lodash or underscore');
    }
    _ = this._;
  }

  capitalize = function(s) {
    return s.charAt(0).toUpperCase() + s.slice(1);
  };

  Key = (function() {
    function Key(_at_name, _at_unique, _at_derive) {
      this.name = _at_name;
      this.unique = _at_unique;
      this.derive = _at_derive != null ? _at_derive : this.name;
      if (_.isString(this.derive)) {
        this.derive = _.property(this.derive);
      }
    }

    return Key;

  })();

  Index = (function() {
    Index.toField = function(name) {
      return "_by_" + name;
    };

    function Index(_at_key) {
      this.key = _at_key;
      this.field = Index.toField(this.key.name);
    }

    Index.prototype.registerOn = function(obj) {
      var keyName;
      keyName = this.key.name;
      obj[this.field] = this;
      return obj["getBy" + (capitalize(keyName))] = this.get.bind(this);
    };

    return Index;

  })();

  UniqueIndex = (function(_super) {
    __extends(UniqueIndex, _super);

    function UniqueIndex() {
      return UniqueIndex.__super__.constructor.apply(this, arguments);
    }

    UniqueIndex.prototype.reindex = function(collection) {
      return this.val = _.indexBy(collection, this.key.derive);
    };

    UniqueIndex.prototype.get = function(k) {
      return this.val[k];
    };

    UniqueIndex.prototype.add = function(object, k) {
      if (k == null) {
        k = this.key.derive(object);
      }
      this.val[k] = object;
      return k;
    };

    UniqueIndex.prototype.remove = function(object, k) {
      if (k == null) {
        k = this.key.derive(object);
      }
      delete this.val[k];
      return k;
    };

    UniqueIndex.prototype.update = function(existing, object) {
      var k;
      k = this.key.derive(object);
      this.remove(existing);
      return this.add(object, k);
    };

    return UniqueIndex;

  })(Index);

  PrimaryIndex = (function(_super) {
    __extends(PrimaryIndex, _super);

    function PrimaryIndex(key) {
      if (!key.unique) {
        throw TypeError("Primary key must be unique");
      }
      PrimaryIndex.__super__.constructor.apply(this, arguments);
    }

    PrimaryIndex.prototype.add = function(object, k) {
      if (k == null) {
        k = this.key.derive(object);
      }
      if (k == null) {
        throw new TypeError("Object must include primary key");
      }
      if (this.val[k] != null) {
        throw new TypeError("Object with primary key already in store");
      }
      return PrimaryIndex.__super__.add.apply(this, arguments);
    };

    PrimaryIndex.prototype.remove = function(object, k) {
      var existing;
      if (k == null) {
        k = this.key.derive(object);
      }
      if (k == null) {
        throw new TypeError("Object must include primary key");
      }
      existing = this.val[k];
      if (existing == null) {
        throw new TypeError("Object not in store");
      }
      return PrimaryIndex.__super__.remove.apply(this, arguments);
    };

    return PrimaryIndex;

  })(UniqueIndex);

  MultiValuedIndex = (function(_super) {
    __extends(MultiValuedIndex, _super);

    function MultiValuedIndex(key, _at_pk) {
      this.pk = _at_pk;
      MultiValuedIndex.__super__.constructor.apply(this, arguments);
    }

    MultiValuedIndex.prototype.reindex = function(collection) {
      return this.val = _.groupBy(collection, this.key.derive);
    };

    MultiValuedIndex.prototype.get = function(k) {
      var _base;
      return (_base = this.val)[k] != null ? _base[k] : _base[k] = [];
    };

    MultiValuedIndex.prototype.add = function(object, k) {
      var _base;
      if (k == null) {
        k = this.key.derive(object);
      }
      return ((_base = this.val)[k] != null ? _base[k] : _base[k] = []).push(object);
    };

    MultiValuedIndex.prototype.remove = function(object, k, pk) {
      var entry, pkDerive, _ref;
      if (k == null) {
        k = this.key.derive(object);
      }
      entry = (_ref = this.val[k]) != null ? _ref : [];
      pkDerive = this.pk.derive;
      return _.remove(entry, function(o) {
        return pk === pkDerive(o);
      });
    };

    MultiValuedIndex.prototype.update = function(existing, object, pk) {
      this.remove(existing, void 0, pk);
      return this.add(object, this.key.derive(object));
    };

    return MultiValuedIndex;

  })(Index);

  Collection = (function() {
    function Collection(_at_collection, _at_pk) {
      this.collection = _at_collection;
      this.pk = _at_pk;
    }

    Collection.prototype.add = function(object) {
      return this.collection.push(object);
    };

    Collection.prototype.remove = function(object, _ignored, pk) {
      var pkDerive;
      pkDerive = this.pk.derive;
      return _.remove(this.collection, function(o) {
        return pk === pkDerive(o);
      });
    };

    Collection.prototype.update = function(existing, object, pk, replace) {
      var pkDerive;
      if (replace == null) {
        replace = false;
      }
      if (replace) {
        pkDerive = this.pk.derive;
        _.remove(this.collection, function(o) {
          return pk === pkDerive(o);
        });
        return this.collection.push(object);
      }
    };

    Collection.prototype.reindex = function() {};

    return Collection;

  })();

  Store = (function() {
    function Store() {
      var collection, i, index, key, keys, _at_collection, _i, _len, _ref;
      _at_collection = arguments[0], keys = 2 <= arguments.length ? __slice.call(arguments, 1) : [];
      this.collection = _at_collection;
      if (!(keys.length > 0)) {
        throw new TypeError("Primary key is required");
      }
      keys = _.map(keys, function(arg, index) {
        if (_.isString(arg)) {
          return new Key(arg, true);
        } else if (_.isFunction(arg)) {
          return new Key(index.toString(), false, arg);
        } else {
          return arg;
        }
      });
      this.primaryIndex = new PrimaryIndex(keys[0]);
      this.indices = (function() {
        var _i, _len, _ref, _results;
        _ref = keys.slice(1);
        _results = [];
        for (i = _i = 0, _len = _ref.length; _i < _len; i = ++_i) {
          key = _ref[i];
          if (key.unique) {
            _results.push(new UniqueIndex(key));
          } else {
            _results.push(new MultiValuedIndex(key, this.primaryIndex.key));
          }
        }
        return _results;
      }).call(this);
      _ref = [this.primaryIndex].concat(this.indices);
      for (_i = 0, _len = _ref.length; _i < _len; _i++) {
        index = _ref[_i];
        index.registerOn(this);
      }
      collection = new Collection(this.collection, this.primaryIndex.key);
      this.indices.push(collection);
      this.reindex();
    }

    Store.prototype.reindex = function() {
      var index, _i, _len, _ref, _results;
      this.primaryIndex.reindex(this.collection);
      _ref = this.indices;
      _results = [];
      for (_i = 0, _len = _ref.length; _i < _len; _i++) {
        index = _ref[_i];
        _results.push(index.reindex(this.collection));
      }
      return _results;
    };

    Store.prototype.getAll = function() {
      return this.collection;
    };

    Store.prototype.getByPk = function(key) {
      return this.primaryIndex.val[key];
    };

    Store.prototype.getBy = function(keyName, key) {
      var index;
      index = this[Index.toField(keyName)];
      if (index == null) {
        throw new TypeError("Invalid key: " + keyName);
      }
      return index.val[key];
    };

    Store.prototype.add = function(object) {
      var index, _i, _len, _ref, _results;
      this.primaryIndex.add(object);
      _ref = this.indices;
      _results = [];
      for (_i = 0, _len = _ref.length; _i < _len; _i++) {
        index = _ref[_i];
        _results.push(index.add(object));
      }
      return _results;
    };

    Store.prototype.remove = function(object) {
      var index, k, _i, _len, _ref, _results;
      k = this.primaryIndex.remove(object);
      _ref = this.indices;
      _results = [];
      for (_i = 0, _len = _ref.length; _i < _len; _i++) {
        index = _ref[_i];
        _results.push(index.remove(object, void 0, k));
      }
      return _results;
    };

    Store.prototype.update = function(existing, object, replace) {
      var index, k, _i, _len, _ref, _results;
      if (replace == null) {
        replace = false;
      }
      k = this.primaryIndex.update(existing, object);
      _ref = this.indices;
      _results = [];
      for (_i = 0, _len = _ref.length; _i < _len; _i++) {
        index = _ref[_i];
        _results.push(index.update(existing, object, k, replace));
      }
      return _results;
    };

    return Store;

  })();

  if (typeof define === "function" && define.amd) {
    define(function() {
      return {
        Store: Store,
        Key: Key
      };
    });
  } else if (typeof module === "object" && module.exports) {
    module.exports.Store = Store;
    module.exports.Key = Key;
  } else {
    this.store = {
      Store: Store,
      Key: Key
    };
  }

}).call(this);
