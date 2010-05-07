#ifndef _FMESH_MESH_
#define _FMESH_MESH_ 1

#include <cstddef>
#include <cstddef>
//#include <cstring>
#include <iostream>
#include <iomanip>
#include <vector>
#include <set>
#include <map>
#include <list>
#include <string>

#include "xtmpl.h"

#define Mesh_V_capacity_doubling_limit 8192
#define Mesh_V_capacity_step_size 1024
#define MESH_EPSILON 1e-15

#ifndef NOT_IMPLEMENTED
#define NOT_IMPLEMENTED (std::cout					\
			 << __FILE__ << "(" << __LINE__ << ")\t"	\
			 << "NOT IMPLEMENTED: "				\
			 << __PRETTY_FUNCTION__ << std::endl);
#endif

namespace fmesh {

  class Xtmpl;
  class Mesh;
  class Dart;
  class MOAint;
  class MOAint3;
  class MOAdouble3;
  class MeshC;

  typedef double Point[3];
  typedef int Int3[3];
  typedef std::pair<int,int> IntPair;
  typedef std::list<int> vertexListT;
  typedef std::set<int> triangleSetT;
  typedef IntPair constrT;
  typedef std::list<constrT> constrListT;
  typedef std::list<Dart> DartList;
  typedef std::pair<Dart,Dart> DartPair;

  struct Vec {  
    static void copy(Point& s, const Point& s0)
    {
      s[0] = s0[0];
      s[1] = s0[1];
      s[2] = s0[2];
    };
    static void rescale(Point& s, double s1)
    {
      s[0] *= s1;
      s[1] *= s1;
      s[2] *= s1;
    };
    static void scale(Point& s, const Point& s0, double s1)
    {
      s[0] = s0[0]*s1;
      s[1] = s0[1]*s1;
      s[2] = s0[2]*s1;
    };
    static void diff(Point& s,const Point& s0, const Point& s1)
    {
      s[0] = s0[0]-s1[0];
      s[1] = s0[1]-s1[1];
      s[2] = s0[2]-s1[2];
    };
    static void sum(Point& s,const Point& s0, const Point& s1)
    {
      s[0] = s0[0]+s1[0];
      s[1] = s0[1]+s1[1];
      s[2] = s0[2]+s1[2];
    };
    static void accum(Point& s, const Point& s0, double s1 = 1.0)
    {
      s[0] += s0[0]*s1;
      s[1] += s0[1]*s1;
      s[2] += s0[2]*s1;
    };
    static double scalar(const Point& s0, const Point& s1)
    {
      return (s0[0]*s1[0]+s0[1]*s1[1]+s0[2]*s1[2]);
    };
    static double length(const Point& s0)
    {
      return (std::sqrt(s0[0]*s0[0]+s0[1]*s0[1]+s0[2]*s0[2]));
    };
    static void cross(Point& s, const Point& s0, const Point& s1)
    {
      s[0] = s0[1]*s1[2]-s0[2]*s1[1];
      s[1] = s0[2]*s1[0]-s0[0]*s1[2];
      s[2] = s0[0]*s1[1]-s0[1]*s1[0];
    };
    static double cross2(const Point& s0, const Point& s1)
    {
      return (s0[0]*s1[1]-s0[1]*s1[0]);
    };
    /*!
      Calculate an arbitrary perpendicular vector.

      Michael M. Stark, Efficient Construction of Perpendicular
      Vectors without Branching, Journal of graphics, gpu, and game
      tools, Vol. 14, No. 1: 55-62, 2009
    */
#define ABS(X) std::fabs(X)
    // #define SIGNBIT(X) (((union { double x; unsigned long n; }(X)).n >> 31))
      // WIll not work: #define SIGNBIT(X) std::signbit(X)
#define SIGNBIT(X) (X < 0)
    static void arbitrary_perpendicular(Point& n, const Point& v)
    {
      const unsigned int uyx = SIGNBIT(ABS(v[0]) - ABS(v[1]));
      const unsigned int uzx = SIGNBIT(ABS(v[0]) - ABS(v[2]));
      const unsigned int uzy = SIGNBIT(ABS(v[1]) - ABS(v[2]));
      const unsigned int xm = uyx & uzx;
      const unsigned int ym = (1^xm) & uzy;
      const unsigned int zm = 1^(xm & ym);
      std::cout << uyx << ' ' << uzx << ' ' << uzy << std::endl;
      std::cout << xm << ' ' << ym << ' ' << zm << std::endl;
      n[0] =  zm*v[1] - ym*v[2];
      n[1] =  xm*v[2] - zm*v[0];
      n[2] =  ym*v[0] - xm*v[1];
    };
  };


  class Mesh {
    friend class Dart;
    friend std::ostream& operator<<(std::ostream& output, const Mesh& M);
  public:
    enum Mtype {Mtype_manifold=0,
		Mtype_plane,
		Mtype_sphere};
  private:
    Mtype type_;
    size_t Vcap_;
    size_t Tcap_;
    size_t nV_;
    size_t nT_;
    bool use_VT_;
    bool use_TTi_;
    Int3 (*TV_);  /* TV[t]  : {v1,v2,v3} */
    Int3 (*TT_);  /* TT[t]  : {t1,t2,t3} */
    int (*VT_);   /* VT[v]  : t,
		     v == TV[t][vi]  for some vi=0,1,2 */
    Int3 (*TTi_); /* TTi[t] : {vi1,vi2,vi3},
		       t == TT[ TT[t][i] ][ TTi[t][i] ] */
    //    double (*S_)[3];
    Point (*S_);
    Xtmpl (*X11_);
    int X11_v_big_limit_;
    
  private:
    Mesh& rebuildTT();

    Mesh& updateVT(const int v, const int t);
    /*!< Change VT[v] only if not linked to a triangle */
    Mesh& setVT(const int v, const int t);
    /* Overwerite current VT[v] info */
    Mesh& updateVTtri(const int t);
    Mesh& setVTtri(const int t);
    Mesh& updateVTtri_private(const int t0);
    Mesh& setVTv_private(const int t0);

    Mesh& rebuildVT();
    Mesh& rebuildTTi();

    void drawX11point(int v, bool fg);
  public:
    void drawX11triangle(int t, bool fg);
  public:
    void redrawX11(std::string str);
    
  public:
    Mesh(void) : type_(Mtype_manifold), Vcap_(0), Tcap_(0),
      nV_(0), nT_(0), use_VT_(false), use_TTi_(true),
      TV_(NULL), TT_(NULL), TTi_(NULL), S_(NULL),
      X11_(NULL), X11_v_big_limit_(0) {};
    Mesh(Mtype manifold_type, size_t Vcapacity, bool use_VT=true, bool use_TTi=false);
    Mesh(const Mesh& M) : type_(Mtype_manifold), Vcap_(0), Tcap_(0),
      nV_(0), nT_(0), use_VT_(true), use_TTi_(false),
      TV_(NULL), TT_(NULL), TTi_(NULL), S_(NULL),
      X11_(NULL), X11_v_big_limit_(0) {
      *this = M;
    };
    Mesh& operator=(const Mesh& M);
    ~Mesh();
    Mesh& clear();

    /*!
      \brief Check the storage capacity, and increase if necessary
    */
    Mesh& check_capacity(size_t nVc, size_t nTc);

    bool useVT() const { return use_VT_; };
    Mesh& useVT(bool use_VT);
    bool useTTi() const { return use_TTi_; };
    Mesh& useTTi(bool use_TTi);

    bool useX11() const { return (X11_!=NULL); };
    void setX11VBigLimit(int lim) { X11_v_big_limit_ = lim; };
    Mesh& useX11(bool use_X11, bool draw_text,
		 int sx = 500, int sy = 500,
		 double minx = -0.05,
		 double maxx = 1.05,
		 double miny = -0.05,
		 double maxy = 1.05,
		 std::string name = "fmesher::Mesh");

    Mtype type() const { return type_; };
    size_t nV() const { return nV_; };
    size_t nT() const { return nT_; };
    const Int3 (*TV() const) { return TV_; };
    const Int3 (*TT() const) { return TT_; };
    const int (*VT() const) { return VT_; };
    const Int3 (*TTi() const) { return TTi_; };
    const Point (*S() const) { return S_; };
    const Int3& TV(int t) const { return TV_[t]; };
    const Int3& TT(int t) const { return TT_[t]; };
    const int& VT(int v) const { return VT_[v]; };
    const Int3& TTi(int t) const { return TTi_[t]; };
    const Point& S(int v) const { return S_[v]; };
    Xtmpl *X11() { return X11_; };
    MOAint3 TVO() const;
    MOAint3 TTO() const;
    MOAint VTO() const;
    MOAint3 TTiO() const;
    MOAdouble3 SO() const;
    
    Mesh& S_set(const double (*S)[3], int nV);
    Mesh& TV_set(const int (*TV)[3], int nT); 
    Mesh& S_append(const double (*S)[3], int nV);
    Mesh& TV_append(const int (*TV)[3], int nT); 

    Dart findPathDirection(const Dart& d0, const Point& s, const int v = -1) const;
    DartPair tracePath(const Dart& d0, const Point& s,
		       const int v = -1, DartList* trace = NULL) const;
    Dart locatePoint(const Dart& d0, const Point& s) const;
    Dart locateVertex(const Dart& d0, const int v) const;
    
    Dart swapEdge(const Dart& d);
    Dart splitEdge(const Dart& d, int v);
    Dart splitTriangle(const Dart& d, int v);

    Mesh& unlinkTriangle(const int t); 
    Mesh& relocateTriangle(const int t_source, const int t_target); 
    int removeTriangle(const int t); 

    /* Traits: */
    double edgeLength(const Dart& d) const;
    void barycentric(const Dart& d, const Point& s, Point& bary) const;
    double triangleArea(const Point& s0, const Point& s1, const Point& s2) const;
    double triangleArea(int t) const;
    void triangleCircumcenter(int t, Point& c) const;
    double triangleCircumcircleRadius(int t) const;
    double triangleShortestEdge(int t) const;
    double triangleLongestEdge(int t) const;
    double edgeEncroached(const Dart& d, const Point& s) const;
    
    /*!
      Compute dart half-space test for a point.
      positive if s is to the left of the edge defined by d.
     */
    double inLeftHalfspace(const Point& s0,
			   const Point& s1,
			   const Point& s) const;
  };



  class MOAint {
    friend std::ostream& operator<<(std::ostream& output, const MOAint& MO);
  private:
    size_t n_;
    const int (*M_);
  public:
    MOAint(const int (*M),size_t n) : n_(n), M_(M) {};
  };

  class MOAint3 {
    friend std::ostream& operator<<(std::ostream& output, const MOAint3& MO);
  private:
    size_t n_;
    const int (*M_)[3];
  public:
    MOAint3(const int (*M)[3],size_t n) : n_(n), M_(M) {};
  };

  class MOAdouble3 {
    friend std::ostream& operator<<(std::ostream& output, const MOAdouble3& MO);
  private:
    size_t n_;
    const double (*M_)[3];
  public:
   MOAdouble3(const double (*M)[3],size_t n) : n_(n), M_(M) {};
  };

  std::ostream& operator<<(std::ostream& output, const Point& MO);


  
  /*! \breif Darts */
  class Dart {
    friend std::ostream& operator<<(std::ostream& output, const Dart& d);
  private:
    const Mesh *M_;
    size_t vi_;
    int edir_;
    int t_;
    
  public:
    Dart(void)
      : M_(NULL), vi_(0), edir_(1), t_(0) {};
    Dart(const Mesh& M, int t=0, int edir=1, size_t vi=0)
      : M_(&M), vi_(vi), edir_(edir), t_(t) {};
    Dart(const Dart& d) : M_(d.M_), vi_(d.vi_),
			  edir_(d.edir_), t_(d.t_) {};
    Dart& operator=(const Dart& d) {
      M_ = d.M_ ;
      vi_ = d.vi_;
      edir_ = d.edir_;
      t_ = d.t_;
      return *this;
    };

    const Mesh* M() const { return M_; };
    int vi() const { return vi_; };
    int edir() const { return edir_; };
    int t() const { return t_; };
    int v() const { if (!M_) return -1; else return M_->TV_[t_][vi_]; };
    /* Opposite vertex; alpha0().v() */
    int vo() const {
      if (!M_) return -1;
      else return M_->TV_[t_][(vi_+(3+edir_))%3];
    };
    /* Adjacent triangle; alpha2().t() */
    int tadj() const {
      if (!M_) return -1;
      else return M_->TT_[t_][(vi_+(3-edir_))%3];
    };

    bool isnull() const { return (!M_); };
    bool operator==(const Dart& d) const {
      return ((d.t_ == t_) &&
	      (d.vi_ == vi_) &&
	      (d.edir_ == edir_));
    };
    bool operator<(const Dart& d) const {
      /* TODO: Add debug check for M_==d.M_ */
      return ((d.t_ < t_) ||
	      ((d.t_ == t_) &&
	       ((d.edir_ < edir_) ||
		((d.edir_ == edir_) &&
		 (d.vi_ < vi_)))));
    };
    bool operator!=(const Dart& d) const {
      return !(d == *this);
    };

    bool onBoundary() const {
      return (M_->TT_[t_][(vi_+(3-edir_))%3] < 0);
    }

    double inLeftHalfspace(const Point& s) const;
    double inCircumcircle(const Point& s) const;
    bool circumcircleOK(void) const;

    bool isSwapable() const
    {
      if (onBoundary())
	return false; /* Not swapable. */
      Dart dh(*this);
      const Point& s00 = M_->S_[dh.v()];
      dh.orbit2();
      const Point& s01 = M_->S_[dh.v()];
      dh.orbit2();
      const Point& s10 = M_->S_[dh.v()];
      dh.orbit2().orbit0rev().orbit2();
      const Point& s11 = M_->S_[dh.v()];
      /* Do both diagonals cross? Swapable. */
      return (((M_->inLeftHalfspace(s00,s01,s10)*
		M_->inLeftHalfspace(s00,s01,s11)) < 0.0) &&
	      ((M_->inLeftHalfspace(s10,s11,s00)*
		M_->inLeftHalfspace(s10,s11,s01)) < 0.0));
    };

    bool isSwapableD() const
    {
      return (!circumcircleOK());
    };

    Dart& unlinkEdge(); 

    /* Graph traversal algebra. */
    Dart& alpha0(void);
    Dart& alpha1(void);
    Dart& alpha2(void);
    Dart& orbit0(void);
    Dart& orbit1(void);
    Dart& orbit2(void);
    Dart& orbit0rev(void);
    Dart& orbit1rev(void);
    Dart& orbit2rev(void);

  };


} /* namespace fmesh */

#endif
