#define _CRT_SECURE_NO_WARNINGS

#include <stdio.h>
#include <stdlib.h>
#include <stdarg.h>

#include <string>
#include <map>
#include <assert.h>
#include <stack>
#include <list>
#include <vector>

using namespace std;

typedef unsigned long long u64;
typedef unsigned int u32;
typedef unsigned short u16;
typedef unsigned char u8;


char xcept_str[128];
#define xcept(fmt,...) {memset(xcept_str,0,sizeof(xcept_str));_snprintf(xcept_str,sizeof(xcept_str)-1,fmt,## __VA_ARGS__);throw xcept_str;}

static wstring wformat(const wchar_t*format,...) {
	wstring res;
	va_list args;
	va_start(args,format);
	size_t len = _vscwprintf(format,args);
	res.resize(len+sizeof(wchar_t));
	wchar_t*buf = (wchar_t*)res.c_str();
	vswprintf_s(buf,len+sizeof(wchar_t),format,args);
	return buf;
}


class c_adm {
public:
	struct c_get {
		const char*p,*ep;
		c_get(const void*buf,size_t len) : p((const char*)buf), ep(p+len) {}
		const char*get(size_t len) {
			const char*np=p+len;
			if (np>ep) xcept("unexpected eof :(");
			const char*r = p;
			p = np;
			return r;
		}
		template<typename t> t&get() {
			return *(t*)get(sizeof(t));
		}
		u64 gu64() {return get<u64>();}
		u32 gu32() {return get<u32>();}
		u16 gu16() {return get<u16>();}
		u8 gu8() {return get<u8>();}
		bool eof() {
			return p>=ep;
		}
	};
	struct c_put {
		char*buf,*p,*e;
		size_t bufsize;
		c_put() : buf(0), p(0), e(0) {}
		~c_put() {if (buf) free(buf);}
		size_t size() {return p-buf;}
		void*getbuf() {return buf;}
		void reset() {
			p = buf;
		}
		void put(const void*data,size_t len) {
			char*np = p + len;
			if (np>e) {
				size_t size = ((e-buf)|0x400) * 2;
				size_t ppos = p-buf;
				buf = (char*)realloc(buf,size);
				p = buf+ppos;
				e = buf+size;
			}
			memcpy(p,data,len);
			p += len;
		}
		template<typename t> void put(const t&v) {
			put((const void*)&v,sizeof(v));
		}
		void pu32(u32 v) {put(v);}
		void pu16(u16 v) {put(v);}
		void pu8(u8 v) {put(v);}
	};
	struct c_attribute {
		enum {t_integer=1,t_float,t_double,t_unsigned_int,t_string,t_bool,t_integer64,t_translate};
		u32 type;
		u32 name;
		union {
			u32 val;
			u32 val32;
			u64 val64;
			float valf;
			double vald;
		};
		c_attribute() {}
		c_attribute(u32 type,u32 name,u32 val) : type(type), name(name), val(val) {}
		c_attribute(u32 type,u32 name,u64 val64) : type(type), name(name), val64(val64) {}
		static c_attribute integer(u32 name,u32 val) {return c_attribute(t_integer,name,val);}
	};
	struct c_node {
		u32 name;
		list<c_attribute> alist;
		list<c_node> nlist;
	};
	c_adm() : next_str_id(0x1000) {}
	list<c_node> nodelist;
	map<u32,wstring> stringmap;
	u32 next_str_id;
	u32 add_str(const wchar_t*str,size_t len) {
		u32 id = next_str_id++;
		while (stringmap.find(id)!=stringmap.end()) id=next_str_id++;
		stringmap[id] = wstring(str,len);
		return id;
	}
	const wchar_t*get_str(u32 id) {return stringmap[id].c_str();}
	void load(const void*buf,size_t len) {
		c_get g(buf,len);
		struct c_nestack {
			c_node node;
			u32 subnodes;
			c_nestack() {}
			c_nestack(c_node node,u32 subnodes) : node(node), subnodes(subnodes) {}
		};
		stack<c_nestack> nstack;
		// I've no idea if this really is version, it could be the number of root nodes or something.
		// ...but I haven't found a file where it wasn't 1, so I'll interpret it as a version number for now.
		u32 version = g.gu32();
		if (version!=1) {printf("Warning: version mismatch, expected %d, got %d. Expect errors.\n",1,version);}
		u32 nodes = 1;
		nstack.push(c_nestack(c_node(),nodes));
		u32 stringcnt = g.gu32();
		for (u32 i=0;i<stringcnt;i++) {
			u32 id = g.gu32();
			u32 len = g.gu32();
			const char*str = g.get(len*sizeof(wchar_t));
			//printf("string %.*ls\n",len,str);
			stringmap[id] = wstring((const wchar_t*)str,len);
		}
		bool done=false;
		while (!done) {
			c_node n;
			n.name = g.gu32();
			//printf("node %ls\n",stringmap[n.name].c_str());
			u32 cnt = g.gu32();
			for (u32 i=0;i<cnt;i++) {
				c_attribute a;
				a.name = g.gu32();
				a.type = g.gu32();
				switch (a.type) {
					case c_attribute::t_integer:
					case c_attribute::t_unsigned_int:
					case c_attribute::t_string:
					case c_attribute::t_bool:
					case c_attribute::t_translate:
						a.val32 = g.gu32();
						break;
					case c_attribute::t_integer64:
						a.val64 = g.gu64();
						break;
					case c_attribute::t_float:
						a.valf = g.get<float>();
						break;
					case c_attribute::t_double:
						a.vald = g.get<double>();
						break;
					default:
						xcept("unknown type %d\n",a.type);
				}
				n.alist.push_back(a);
			}
			u32 subnodes = g.gu32();
			//printf("subnodes: %d\n",subnodes);
			nodes--;
			nstack.top().subnodes = nodes;
			if (subnodes) {
				nstack.push(c_nestack(n,subnodes));
				nodes = subnodes;
			} else {
				nstack.top().node.nlist.push_back(n);
				//printf("nodes is %d\n",nodes);
				while (nodes==0) {
					//printf("nstack.size() is %d\n",nstack.size());
					if (nstack.size()==1) {
						if (!g.eof()) xcept("expected eof!");
						done=true;
						break;
					}
					c_nestack ne = nstack.top();
					//printf("pop %ls\n",get_str(ne.node.name));
					nstack.pop();
					c_node n = ne.node;
					nstack.top().node.nlist.push_back(n);
					nodes = nstack.top().subnodes;
				}
			}
		}
		nodelist = nstack.top().node.nlist;

	}
	void dump_node(const c_node&n,wstring&s) {
		s += wformat(L"[%ls]\r\n",get_str(n.name));
		for (list<c_attribute>::const_iterator i=n.alist.begin();i!=n.alist.end();++i) {
			const c_attribute&a=*i;
			const wchar_t*pname = get_str(a.name);
			switch (a.type) {
				case c_attribute::t_integer: // integer
					s += wformat(L"<INTEGER>%ls:%d\r\n",pname,a.val);
					break;
				case c_attribute::t_float:
					s += wformat(L"<FLOAT>%ls:%f\r\n",pname,a.valf);
					break;
				case c_attribute::t_double:
					s += wformat(L"<DOUBLE>%ls:%f\r\n",pname,a.vald);
					break;
				case c_attribute::t_unsigned_int:
					s += wformat(L"<UNSIGNED INT>%ls:%u\r\n",pname,a.val);
					break;
				case c_attribute::t_string: // string
					s += wformat(L"<STRING>%ls:%ls\r\n",pname,get_str(a.val));
					break;
				case c_attribute::t_bool: // bool
					s += wformat(L"<BOOL>%ls:%s\r\n",pname,a.val?L"true":L"false");
					break;
				case c_attribute::t_integer64: // integer64
					s += wformat(L"<INTEGER64>%ls:%I64d\r\n",pname,a.val64);
					break;
				case c_attribute::t_translate:
					s += wformat(L"<TRANSLATE>%ls:%ls\r\n",pname,get_str(a.val));
					break;
				default:
					xcept("dump_node: bad attribute type %d\r\n",a.type);
			}
		}
		for (list<c_node>::const_iterator i=n.nlist.begin();i!=n.nlist.end();++i) {
			dump_node(*i,s);
		}
		s += wformat(L"[/%ls]\r\n",get_str(n.name));
	}
	void dump(wstring&s) {
		s=L"";
		for (list<c_node>::const_iterator i=nodelist.begin();i!=nodelist.end();++i) {
			dump_node(*i,s);
		}
	}
	void parse(const wchar_t*p) {
		int line = 1;
		stack<c_node> nstack;
		c_node root;
		root.name = -1;
		nstack.push(root);
		while (*p) {
			while (*p==' '||*p=='\t'||*p=='\n'||*p=='\r') {if (*p=='\n') line++; p++;}
			if (!*p) break;
			if (*p=='[') {
				++p;
				if (*p=='/') {
					if (nstack.size()==1) xcept("line %d: unexpected close; no matching open",line);
					c_node n = nstack.top();
					nstack.pop();
					const wchar_t*np=++p;
					while (*p!=']') {if (!*p) xcept("unexpected eof :(");p++;}
					const wchar_t*name = get_str(n.name);
					size_t namelen = wcslen(name);
					if (_wcsnicmp(np,name,(size_t)(p-np)<namelen?p-np:namelen)) xcept("line %d: close mismatch; got '%.*ls', expected '%ls'",line,p-np,np,name);
					nstack.top().nlist.push_back(n);
				} else {
					c_node n;
					const wchar_t*np=p;
					while (*p!=']') {if (!*p) xcept("unexpected eof :(");p++;}
					n.name = add_str(np,p-np);
					nstack.push(n);
				}
			} else if (*p=='<') {
				c_attribute a;
				const wchar_t*np=++p;
				while (*p!='>') {if (!*p) xcept("unexpected eof :(");p++;}
				wstring s = wstring(np,p-np);
				const wchar_t*ps=s.c_str();
				np = ++p;
				while (*p!=':') {if (!*p) xcept("unexpected eof :(");p++;}
				a.name = add_str(np,p-np);
				np = ++p;
				while (*p!='\n'&&*p!='\r') {if (*p=='\n') line++;if (!*p) xcept("unexpected eof :(");p++;}
				if (!_wcsicmp(ps,L"integer")) {
					a.type = c_attribute::t_integer;
					a.val32 = _wtoi(np);
				} else if (!_wcsicmp(ps,L"float")) {
					a.type = c_attribute::t_float;
					a.valf = (float)_wtof(np);
				} else if (!_wcsicmp(ps,L"double")) {
					a.type = c_attribute::t_integer;
					a.vald = _wtof(np);
				} else if (!_wcsicmp(ps,L"unsigned int")) {
					a.type = c_attribute::t_unsigned_int;
					a.val32 = wcstoul(np,0,10);
				} else if (!_wcsicmp(ps,L"string")) {
					a.type = c_attribute::t_string;
					a.val = add_str(np,p-np);
				} else if (!_wcsicmp(ps,L"bool")) {
					a.type = c_attribute::t_bool;
					if (!_wcsnicmp(L"true",np,p-np<4?p-np:4) || _wtoi(np)) a.val = 1;
					else a.val = 0;
				} else if (!_wcsicmp(ps,L"integer64")) {
					a.type = c_attribute::t_integer64;
					a.val64 = _wtoi64(np);
				} else if (!_wcsicmp(ps,L"translate")) {
					a.type = c_attribute::t_translate;
					a.val = add_str(np,p-np);
				}
				nstack.top().alist.push_back(a);
			} else {
				//printf("%ls\n",p);
				xcept("line %d: expected '[' or '<', got '%c'",line,*p);
			}
			p++;
		}
		if (nstack.size()!=1) xcept("unexpected eof, there are %d open tags",nstack.size()-1);
		nodelist = nstack.top().nlist;
	}
	void save_node(const c_node&node,c_put&out) {
		out.pu32(node.name);
		out.pu32(node.alist.size());
		for (list<c_attribute>::const_iterator i=node.alist.begin();i!=node.alist.end();++i) {
			const c_attribute&a = *i;
			out.pu32(a.name);
			out.pu32(a.type);
			switch (a.type) {
				case c_attribute::t_integer:
				case c_attribute::t_unsigned_int:
				case c_attribute::t_string:
				case c_attribute::t_bool:
				case c_attribute::t_translate:
					out.pu32(a.val32);
					break;
				case c_attribute::t_integer64:
					out.put(a.val64);
					break;
				case c_attribute::t_float:
					out.put(a.valf);
					break;
				case c_attribute::t_double:
					out.put(a.vald);
					break;
				default:
					xcept("unknown type %d\n",a.type);
			}
		}
		out.pu32(node.nlist.size());
		//printf("node.nlist.size() is %d\n",node.nlist.size());
		for (list<c_node>::const_iterator i=node.nlist.begin();i!=node.nlist.end();++i) {
			save_node(*i,out);
		}
	}
	void save(c_put&out) {
		out.reset();
		out.pu32(1);
		out.pu32(stringmap.size());
		for (map<u32,wstring>::const_iterator i=stringmap.begin();i!=stringmap.end();++i) {
			out.pu32(i->first);
			out.pu32(i->second.length());
			out.put(i->second.c_str(),i->second.length()*sizeof(wchar_t));
		}
		for (list<c_node>::const_iterator i=nodelist.begin();i!=nodelist.end();++i) {
			save_node(*i,out);
		}
	}
};



int main(int argc,const char**argv) {

	try {

		assert(sizeof(wchar_t)==2);

		if (argc!=2) xcept("need argument: file to convert");

		const char*n = argv[1];

		FILE*f = fopen(n,"rb");
		if (!f) xcept("failed to open '%s' for reading",n);
		fseek(f,0,SEEK_END);
		size_t size = ftell(f);
		fseek(f,0,SEEK_SET);

		char*buf = (char*)malloc(size+2);
		fread(buf,size,1,f);
		fclose(f);

		buf[size] = 0;
		buf[size+1] = 0;

		int is_dat=0;

		const char*ext = strrchr(n,'.');
		if (!ext) ext=n+strlen(n);
		if (!strcmp(ext,".dat")) is_dat=1;
		else if (!strcmp(ext,".adm")) is_dat=2;

		const wchar_t*p = (wchar_t*)buf;
		if (*p==0xfeff) {p++;is_dat=1;} // check for and ignore byte-order-mark

		if (!is_dat) {
			if (*p=='[') is_dat=1;
		}
		c_adm a;
		if (is_dat==1) {
			string fn = string(n) + ".adm";
			printf("parsing dat file...\n");
			a.parse(p);
			f = fopen(fn.c_str(),"wb");
			if (!f) xcept("failed to open %s for writing",fn.c_str());
			c_adm::c_put p;
			a.save(p);
			fwrite(p.getbuf(),p.size(),1,f);
			fclose(f);
			printf("saved as '%s'\n",fn.c_str());
		} else {
			string fn = string(n,ext-n);
			if (!*ext) fn+=".dat";
			printf("loading adm file...\n");
			a.load(buf,size);
			f = fopen(fn.c_str(),"wb");
			if (!f) xcept("failed to open %s for writing",fn.c_str());
			wstring s;
			a.dump(s);
			fwrite("\xff\xfe",2,1,f); // byte-order-mark
			fwrite(s.c_str(),s.length()*sizeof(wchar_t),1,f);
			fclose(f);
			printf("saved as '%s'\n",fn.c_str());
		}
	} catch (const char*e) {
		printf(" [exception] %s\n",e);
		return -1;
	}
	return 0;
}

