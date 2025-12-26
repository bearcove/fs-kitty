#include <stdint.h>
#include <stdbool.h> 
typedef struct RustStr { uint8_t* const start; uintptr_t len; } RustStr;
typedef struct __private__FfiSlice { void* const start; uintptr_t len; } __private__FfiSlice;
void* __swift_bridge__null_pointer(void);


typedef struct __private__OptionU8 { uint8_t val; bool is_some; } __private__OptionU8;
typedef struct __private__OptionI8 { int8_t val; bool is_some; } __private__OptionI8;
typedef struct __private__OptionU16 { uint16_t val; bool is_some; } __private__OptionU16;
typedef struct __private__OptionI16 { int16_t val; bool is_some; } __private__OptionI16;
typedef struct __private__OptionU32 { uint32_t val; bool is_some; } __private__OptionU32;
typedef struct __private__OptionI32 { int32_t val; bool is_some; } __private__OptionI32;
typedef struct __private__OptionU64 { uint64_t val; bool is_some; } __private__OptionU64;
typedef struct __private__OptionI64 { int64_t val; bool is_some; } __private__OptionI64;
typedef struct __private__OptionUsize { uintptr_t val; bool is_some; } __private__OptionUsize;
typedef struct __private__OptionIsize { intptr_t val; bool is_some; } __private__OptionIsize;
typedef struct __private__OptionF32 { float val; bool is_some; } __private__OptionF32;
typedef struct __private__OptionF64 { double val; bool is_some; } __private__OptionF64;
typedef struct __private__OptionBool { bool val; bool is_some; } __private__OptionBool;

void* __swift_bridge__$Vec_u8$new();
void __swift_bridge__$Vec_u8$_free(void* const vec);
uintptr_t __swift_bridge__$Vec_u8$len(void* const vec);
void __swift_bridge__$Vec_u8$push(void* const vec, uint8_t val);
__private__OptionU8 __swift_bridge__$Vec_u8$pop(void* const vec);
__private__OptionU8 __swift_bridge__$Vec_u8$get(void* const vec, uintptr_t index);
__private__OptionU8 __swift_bridge__$Vec_u8$get_mut(void* const vec, uintptr_t index);
uint8_t const * __swift_bridge__$Vec_u8$as_ptr(void* const vec);

void* __swift_bridge__$Vec_u16$new();
void __swift_bridge__$Vec_u16$_free(void* const vec);
uintptr_t __swift_bridge__$Vec_u16$len(void* const vec);
void __swift_bridge__$Vec_u16$push(void* const vec, uint16_t val);
__private__OptionU16 __swift_bridge__$Vec_u16$pop(void* const vec);
__private__OptionU16 __swift_bridge__$Vec_u16$get(void* const vec, uintptr_t index);
__private__OptionU16 __swift_bridge__$Vec_u16$get_mut(void* const vec, uintptr_t index);
uint16_t const * __swift_bridge__$Vec_u16$as_ptr(void* const vec);

void* __swift_bridge__$Vec_u32$new();
void __swift_bridge__$Vec_u32$_free(void* const vec);
uintptr_t __swift_bridge__$Vec_u32$len(void* const vec);
void __swift_bridge__$Vec_u32$push(void* const vec, uint32_t val);
__private__OptionU32 __swift_bridge__$Vec_u32$pop(void* const vec);
__private__OptionU32 __swift_bridge__$Vec_u32$get(void* const vec, uintptr_t index);
__private__OptionU32 __swift_bridge__$Vec_u32$get_mut(void* const vec, uintptr_t index);
uint32_t const * __swift_bridge__$Vec_u32$as_ptr(void* const vec);

void* __swift_bridge__$Vec_u64$new();
void __swift_bridge__$Vec_u64$_free(void* const vec);
uintptr_t __swift_bridge__$Vec_u64$len(void* const vec);
void __swift_bridge__$Vec_u64$push(void* const vec, uint64_t val);
__private__OptionU64 __swift_bridge__$Vec_u64$pop(void* const vec);
__private__OptionU64 __swift_bridge__$Vec_u64$get(void* const vec, uintptr_t index);
__private__OptionU64 __swift_bridge__$Vec_u64$get_mut(void* const vec, uintptr_t index);
uint64_t const * __swift_bridge__$Vec_u64$as_ptr(void* const vec);

void* __swift_bridge__$Vec_usize$new();
void __swift_bridge__$Vec_usize$_free(void* const vec);
uintptr_t __swift_bridge__$Vec_usize$len(void* const vec);
void __swift_bridge__$Vec_usize$push(void* const vec, uintptr_t val);
__private__OptionUsize __swift_bridge__$Vec_usize$pop(void* const vec);
__private__OptionUsize __swift_bridge__$Vec_usize$get(void* const vec, uintptr_t index);
__private__OptionUsize __swift_bridge__$Vec_usize$get_mut(void* const vec, uintptr_t index);
uintptr_t const * __swift_bridge__$Vec_usize$as_ptr(void* const vec);

void* __swift_bridge__$Vec_i8$new();
void __swift_bridge__$Vec_i8$_free(void* const vec);
uintptr_t __swift_bridge__$Vec_i8$len(void* const vec);
void __swift_bridge__$Vec_i8$push(void* const vec, int8_t val);
__private__OptionI8 __swift_bridge__$Vec_i8$pop(void* const vec);
__private__OptionI8 __swift_bridge__$Vec_i8$get(void* const vec, uintptr_t index);
__private__OptionI8 __swift_bridge__$Vec_i8$get_mut(void* const vec, uintptr_t index);
int8_t const * __swift_bridge__$Vec_i8$as_ptr(void* const vec);

void* __swift_bridge__$Vec_i16$new();
void __swift_bridge__$Vec_i16$_free(void* const vec);
uintptr_t __swift_bridge__$Vec_i16$len(void* const vec);
void __swift_bridge__$Vec_i16$push(void* const vec, int16_t val);
__private__OptionI16 __swift_bridge__$Vec_i16$pop(void* const vec);
__private__OptionI16 __swift_bridge__$Vec_i16$get(void* const vec, uintptr_t index);
__private__OptionI16 __swift_bridge__$Vec_i16$get_mut(void* const vec, uintptr_t index);
int16_t const * __swift_bridge__$Vec_i16$as_ptr(void* const vec);

void* __swift_bridge__$Vec_i32$new();
void __swift_bridge__$Vec_i32$_free(void* const vec);
uintptr_t __swift_bridge__$Vec_i32$len(void* const vec);
void __swift_bridge__$Vec_i32$push(void* const vec, int32_t val);
__private__OptionI32 __swift_bridge__$Vec_i32$pop(void* const vec);
__private__OptionI32 __swift_bridge__$Vec_i32$get(void* const vec, uintptr_t index);
__private__OptionI32 __swift_bridge__$Vec_i32$get_mut(void* const vec, uintptr_t index);
int32_t const * __swift_bridge__$Vec_i32$as_ptr(void* const vec);

void* __swift_bridge__$Vec_i64$new();
void __swift_bridge__$Vec_i64$_free(void* const vec);
uintptr_t __swift_bridge__$Vec_i64$len(void* const vec);
void __swift_bridge__$Vec_i64$push(void* const vec, int64_t val);
__private__OptionI64 __swift_bridge__$Vec_i64$pop(void* const vec);
__private__OptionI64 __swift_bridge__$Vec_i64$get(void* const vec, uintptr_t index);
__private__OptionI64 __swift_bridge__$Vec_i64$get_mut(void* const vec, uintptr_t index);
int64_t const * __swift_bridge__$Vec_i64$as_ptr(void* const vec);

void* __swift_bridge__$Vec_isize$new();
void __swift_bridge__$Vec_isize$_free(void* const vec);
uintptr_t __swift_bridge__$Vec_isize$len(void* const vec);
void __swift_bridge__$Vec_isize$push(void* const vec, intptr_t val);
__private__OptionIsize __swift_bridge__$Vec_isize$pop(void* const vec);
__private__OptionIsize __swift_bridge__$Vec_isize$get(void* const vec, uintptr_t index);
__private__OptionIsize __swift_bridge__$Vec_isize$get_mut(void* const vec, uintptr_t index);
intptr_t const * __swift_bridge__$Vec_isize$as_ptr(void* const vec);

void* __swift_bridge__$Vec_bool$new();
void __swift_bridge__$Vec_bool$_free(void* const vec);
uintptr_t __swift_bridge__$Vec_bool$len(void* const vec);
void __swift_bridge__$Vec_bool$push(void* const vec, bool val);
__private__OptionBool __swift_bridge__$Vec_bool$pop(void* const vec);
__private__OptionBool __swift_bridge__$Vec_bool$get(void* const vec, uintptr_t index);
__private__OptionBool __swift_bridge__$Vec_bool$get_mut(void* const vec, uintptr_t index);
bool const * __swift_bridge__$Vec_bool$as_ptr(void* const vec);

void* __swift_bridge__$Vec_f32$new();
void __swift_bridge__$Vec_f32$_free(void* const vec);
uintptr_t __swift_bridge__$Vec_f32$len(void* const vec);
void __swift_bridge__$Vec_f32$push(void* const vec, float val);
__private__OptionF32 __swift_bridge__$Vec_f32$pop(void* const vec);
__private__OptionF32 __swift_bridge__$Vec_f32$get(void* const vec, uintptr_t index);
__private__OptionF32 __swift_bridge__$Vec_f32$get_mut(void* const vec, uintptr_t index);
float const * __swift_bridge__$Vec_f32$as_ptr(void* const vec);

void* __swift_bridge__$Vec_f64$new();
void __swift_bridge__$Vec_f64$_free(void* const vec);
uintptr_t __swift_bridge__$Vec_f64$len(void* const vec);
void __swift_bridge__$Vec_f64$push(void* const vec, double val);
__private__OptionF64 __swift_bridge__$Vec_f64$pop(void* const vec);
__private__OptionF64 __swift_bridge__$Vec_f64$get(void* const vec, uintptr_t index);
__private__OptionF64 __swift_bridge__$Vec_f64$get_mut(void* const vec, uintptr_t index);
double const * __swift_bridge__$Vec_f64$as_ptr(void* const vec);

#include <stdint.h>
typedef struct RustString RustString;
void __swift_bridge__$RustString$_free(void* self);

void* __swift_bridge__$Vec_RustString$new(void);
void __swift_bridge__$Vec_RustString$drop(void* vec_ptr);
void __swift_bridge__$Vec_RustString$push(void* vec_ptr, void* item_ptr);
void* __swift_bridge__$Vec_RustString$pop(void* vec_ptr);
void* __swift_bridge__$Vec_RustString$get(void* vec_ptr, uintptr_t index);
void* __swift_bridge__$Vec_RustString$get_mut(void* vec_ptr, uintptr_t index);
uintptr_t __swift_bridge__$Vec_RustString$len(void* vec_ptr);
void* __swift_bridge__$Vec_RustString$as_ptr(void* vec_ptr);

void* __swift_bridge__$RustString$new(void);
void* __swift_bridge__$RustString$new_with_str(struct RustStr str);
uintptr_t __swift_bridge__$RustString$len(void* self);
struct RustStr __swift_bridge__$RustString$as_str(void* self);
struct RustStr __swift_bridge__$RustString$trim(void* self);
bool __swift_bridge__$RustStr$partial_eq(struct RustStr lhs, struct RustStr rhs);


void __swift_bridge__$call_boxed_fn_once_no_args_no_return(void* boxed_fnonce);
void __swift_bridge__$free_boxed_fn_once_no_args_no_return(void* boxed_fnonce);


struct __private__ResultPtrAndPtr { bool is_ok; void* ok_or_err; };
// File automatically generated by swift-bridge.
#include <stdint.h>
#include <stdbool.h>
typedef struct __swift_bridge__$FfiLookupResult { uint64_t item_id; uint8_t item_type; int32_t error; } __swift_bridge__$FfiLookupResult;
typedef struct __swift_bridge__$Option$FfiLookupResult { bool is_some; __swift_bridge__$FfiLookupResult val; } __swift_bridge__$Option$FfiLookupResult;
typedef struct __swift_bridge__$FfiItemAttributes { uint64_t item_id; uint8_t item_type; uint64_t size; uint64_t modified_time; uint64_t created_time; uint32_t mode; int32_t error; } __swift_bridge__$FfiItemAttributes;
typedef struct __swift_bridge__$Option$FfiItemAttributes { bool is_some; __swift_bridge__$FfiItemAttributes val; } __swift_bridge__$Option$FfiItemAttributes;
typedef struct __swift_bridge__$FfiReadDirResult { void* names; void* item_ids; void* item_types; uint64_t next_cursor; int32_t error; } __swift_bridge__$FfiReadDirResult;
typedef struct __swift_bridge__$Option$FfiReadDirResult { bool is_some; __swift_bridge__$FfiReadDirResult val; } __swift_bridge__$Option$FfiReadDirResult;
typedef struct __swift_bridge__$FfiReadResult { void* data; int32_t error; } __swift_bridge__$FfiReadResult;
typedef struct __swift_bridge__$Option$FfiReadResult { bool is_some; __swift_bridge__$FfiReadResult val; } __swift_bridge__$Option$FfiReadResult;
typedef struct __swift_bridge__$FfiWriteResult { uint64_t bytes_written; int32_t error; } __swift_bridge__$FfiWriteResult;
typedef struct __swift_bridge__$Option$FfiWriteResult { bool is_some; __swift_bridge__$FfiWriteResult val; } __swift_bridge__$Option$FfiWriteResult;
typedef struct __swift_bridge__$FfiCreateResult { uint64_t item_id; int32_t error; } __swift_bridge__$FfiCreateResult;
typedef struct __swift_bridge__$Option$FfiCreateResult { bool is_some; __swift_bridge__$FfiCreateResult val; } __swift_bridge__$Option$FfiCreateResult;
typedef struct __swift_bridge__$FfiVfsResult { int32_t error; } __swift_bridge__$FfiVfsResult;
typedef struct __swift_bridge__$Option$FfiVfsResult { bool is_some; __swift_bridge__$FfiVfsResult val; } __swift_bridge__$Option$FfiVfsResult;
int32_t __swift_bridge__$add(int32_t a, int32_t b);
void __swift_bridge__$async_add(void* callback_wrapper, void __swift_bridge__$async_add$async(void* callback_wrapper, int32_t ret), int32_t a, int32_t b);
void __swift_bridge__$async_greet(void* callback_wrapper, void __swift_bridge__$async_greet$async(void* callback_wrapper, void* ret), void* name);
void* __swift_bridge__$vfs_connect(void* addr);
void __swift_bridge__$vfs_disconnect(void);
struct __private__ResultPtrAndPtr __swift_bridge__$vfs_ping(void);
struct __swift_bridge__$ResultFfiLookupResultAndString __swift_bridge__$vfs_lookup(uint64_t parent_id, void* name);
struct __swift_bridge__$ResultFfiItemAttributesAndString __swift_bridge__$vfs_get_attributes(uint64_t item_id);
struct __swift_bridge__$ResultFfiReadDirResultAndString __swift_bridge__$vfs_read_dir(uint64_t item_id, uint64_t cursor);
struct __swift_bridge__$ResultFfiReadResultAndString __swift_bridge__$vfs_read(uint64_t item_id, uint64_t offset, uint64_t len);
struct __swift_bridge__$ResultFfiWriteResultAndString __swift_bridge__$vfs_write(uint64_t item_id, uint64_t offset, void* data);
struct __swift_bridge__$ResultFfiCreateResultAndString __swift_bridge__$vfs_create(uint64_t parent_id, void* name, uint8_t item_type);
struct __swift_bridge__$ResultFfiVfsResultAndString __swift_bridge__$vfs_delete(uint64_t item_id);
struct __swift_bridge__$ResultFfiVfsResultAndString __swift_bridge__$vfs_rename(uint64_t item_id, uint64_t new_parent_id, void* new_name);
typedef enum __swift_bridge__$ResultFfiLookupResultAndString$Tag {__swift_bridge__$ResultFfiLookupResultAndString$ResultOk, __swift_bridge__$ResultFfiLookupResultAndString$ResultErr} __swift_bridge__$ResultFfiLookupResultAndString$Tag;
union __swift_bridge__$ResultFfiLookupResultAndString$Fields {struct __swift_bridge__$FfiLookupResult ok; void* err;};
typedef struct __swift_bridge__$ResultFfiLookupResultAndString{__swift_bridge__$ResultFfiLookupResultAndString$Tag tag; union __swift_bridge__$ResultFfiLookupResultAndString$Fields payload;} __swift_bridge__$ResultFfiLookupResultAndString;
typedef enum __swift_bridge__$ResultFfiItemAttributesAndString$Tag {__swift_bridge__$ResultFfiItemAttributesAndString$ResultOk, __swift_bridge__$ResultFfiItemAttributesAndString$ResultErr} __swift_bridge__$ResultFfiItemAttributesAndString$Tag;
union __swift_bridge__$ResultFfiItemAttributesAndString$Fields {struct __swift_bridge__$FfiItemAttributes ok; void* err;};
typedef struct __swift_bridge__$ResultFfiItemAttributesAndString{__swift_bridge__$ResultFfiItemAttributesAndString$Tag tag; union __swift_bridge__$ResultFfiItemAttributesAndString$Fields payload;} __swift_bridge__$ResultFfiItemAttributesAndString;
typedef enum __swift_bridge__$ResultFfiReadDirResultAndString$Tag {__swift_bridge__$ResultFfiReadDirResultAndString$ResultOk, __swift_bridge__$ResultFfiReadDirResultAndString$ResultErr} __swift_bridge__$ResultFfiReadDirResultAndString$Tag;
union __swift_bridge__$ResultFfiReadDirResultAndString$Fields {struct __swift_bridge__$FfiReadDirResult ok; void* err;};
typedef struct __swift_bridge__$ResultFfiReadDirResultAndString{__swift_bridge__$ResultFfiReadDirResultAndString$Tag tag; union __swift_bridge__$ResultFfiReadDirResultAndString$Fields payload;} __swift_bridge__$ResultFfiReadDirResultAndString;
typedef enum __swift_bridge__$ResultFfiReadResultAndString$Tag {__swift_bridge__$ResultFfiReadResultAndString$ResultOk, __swift_bridge__$ResultFfiReadResultAndString$ResultErr} __swift_bridge__$ResultFfiReadResultAndString$Tag;
union __swift_bridge__$ResultFfiReadResultAndString$Fields {struct __swift_bridge__$FfiReadResult ok; void* err;};
typedef struct __swift_bridge__$ResultFfiReadResultAndString{__swift_bridge__$ResultFfiReadResultAndString$Tag tag; union __swift_bridge__$ResultFfiReadResultAndString$Fields payload;} __swift_bridge__$ResultFfiReadResultAndString;
typedef enum __swift_bridge__$ResultFfiWriteResultAndString$Tag {__swift_bridge__$ResultFfiWriteResultAndString$ResultOk, __swift_bridge__$ResultFfiWriteResultAndString$ResultErr} __swift_bridge__$ResultFfiWriteResultAndString$Tag;
union __swift_bridge__$ResultFfiWriteResultAndString$Fields {struct __swift_bridge__$FfiWriteResult ok; void* err;};
typedef struct __swift_bridge__$ResultFfiWriteResultAndString{__swift_bridge__$ResultFfiWriteResultAndString$Tag tag; union __swift_bridge__$ResultFfiWriteResultAndString$Fields payload;} __swift_bridge__$ResultFfiWriteResultAndString;
typedef enum __swift_bridge__$ResultFfiCreateResultAndString$Tag {__swift_bridge__$ResultFfiCreateResultAndString$ResultOk, __swift_bridge__$ResultFfiCreateResultAndString$ResultErr} __swift_bridge__$ResultFfiCreateResultAndString$Tag;
union __swift_bridge__$ResultFfiCreateResultAndString$Fields {struct __swift_bridge__$FfiCreateResult ok; void* err;};
typedef struct __swift_bridge__$ResultFfiCreateResultAndString{__swift_bridge__$ResultFfiCreateResultAndString$Tag tag; union __swift_bridge__$ResultFfiCreateResultAndString$Fields payload;} __swift_bridge__$ResultFfiCreateResultAndString;
typedef enum __swift_bridge__$ResultFfiVfsResultAndString$Tag {__swift_bridge__$ResultFfiVfsResultAndString$ResultOk, __swift_bridge__$ResultFfiVfsResultAndString$ResultErr} __swift_bridge__$ResultFfiVfsResultAndString$Tag;
union __swift_bridge__$ResultFfiVfsResultAndString$Fields {struct __swift_bridge__$FfiVfsResult ok; void* err;};
typedef struct __swift_bridge__$ResultFfiVfsResultAndString{__swift_bridge__$ResultFfiVfsResultAndString$Tag tag; union __swift_bridge__$ResultFfiVfsResultAndString$Fields payload;} __swift_bridge__$ResultFfiVfsResultAndString;


