/* This file is generated by "mtxrun --script "mtx-wtoc.lua" from the metapost cweb files. */


# ifndef MPSTRINGS_H
# define MPSTRINGS_H 1

# include "mp.h"

void *mp_aux_copy_strings_entry (const void *p);
extern char *mp_strdup  (const char *s);
extern char *mp_strndup (const char *s, size_t l);
extern int   mp_strcmp  (const char *a, const char *b);
extern void mp_initialize_strings (MP mp);
extern void mp_dealloc_strings    (MP mp);
char      *mp_str         (MP mp, mp_string s);
mp_string  mp_rtsl        (MP mp, const char *s, size_t l);
mp_string  mp_rts         (MP mp, const char *s);
mp_string  mp_make_string (MP mp);
extern void mp_append_char (MP mp, unsigned char c);
extern void mp_append_str  (MP mp, const char *s);
extern void mp_str_room    (MP mp, int wsize);
void mp_reset_cur_string (MP mp);
# define MAX_STR_REF    127
# define add_str_ref(A) { if ( (A)->refs < MAX_STR_REF ) ((A)->refs)++; }
# define delete_str_ref(A) do {  \
    if ((A)->refs < MAX_STR_REF) { \
        if ((A)->refs > 1) \
            ((A)->refs)--;  \
        else \
            mp_flush_string(mp, (A)); \
    } \
  } while (0)
void mp_flush_string (MP mp, mp_string s);
mp_string mp_intern (MP mp, const char *s);
mp_string mp_make_string (MP mp);
int mp_str_vs_str (MP mp, mp_string s, mp_string t);
mp_string mp_cat (MP mp, mp_string a, mp_string b);
mp_string mp_chop_string (MP mp, mp_string s, int a, int b);


# endif

